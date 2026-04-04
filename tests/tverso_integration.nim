{.experimental: "strictFuncs".}
## Integration test: verso against live PostgreSQL server.
##
## Requires: podman run -d --name verso-pg -p 5432:5432 -e POSTGRES_PASSWORD=test -e POSTGRES_DB=verso docker.io/postgres:17

import std/[unittest, strutils]
import basis/code/choice
import basis/code/verso
import postgres/api

const CONNINFO = "host=localhost port=5432 dbname=verso user=postgres password=test"

suite "verso postgres integration":
  var db: PGDatabase

  setup:
    db = api.open(CONNINFO)
    discard db.exec(SqlText("DROP TABLE IF EXISTS verso_delta"))
    discard db.exec(SqlText("DROP TABLE IF EXISTS verso_entity"))
    discard db.exec(SqlText("DROP TABLE IF EXISTS verso_mutation"))
    discard db.exec(SqlText("CREATE TABLE verso_mutation (id TEXT PRIMARY KEY, parent TEXT, actor TEXT, timestamp BIGINT, plan_version INT, space TEXT, partition INT)"))
    discard db.exec(SqlText("CREATE TABLE verso_entity (mutation_id TEXT, link_type TEXT, instance_id TEXT, life INT)"))
    discard db.exec(SqlText("CREATE TABLE verso_delta (mutation_id TEXT, knot TEXT, value TEXT, op INT, life INT)"))

  teardown:
    db.close()

  test "store and load mutation":
    var m = Mutation(parent: "", actor: "admin", timestamp: 100,
                     plan_version: 1, space: "home", partition: pData,
                     entities: @[entity("Person", "abc")],
                     deltas: @[delta_add("name", "Alice")])
    stamp(m)

    discard db.exec(SqlText("INSERT INTO verso_mutation VALUES ($1,$2,$3,$4,$5,$6,$7)"),
            [m.id, m.parent, m.actor, $m.timestamp, $m.plan_version, m.space, $ord(m.partition)])

    for e in m.entities:
      discard db.exec(SqlText("INSERT INTO verso_entity VALUES ($1,$2,$3,$4)"),
              [m.id, e.link_type, e.instance_id, $ord(e.life)])

    for d in m.deltas:
      discard db.exec(SqlText("INSERT INTO verso_delta VALUES ($1,$2,$3,$4,$5)"),
              [m.id, d.knot, d.value, $ord(d.op), $ord(d.life)])

    let r = db.exec(SqlText("SELECT id, parent, actor, timestamp, plan_version, space, partition FROM verso_mutation WHERE id = $1"), [m.id])
    check r.ntuples == 1
    check r.getvalue(RowIdx(0), ColIdx(0)) == m.id
    check r.getvalue(RowIdx(0), ColIdx(2)) == "admin"
    check r.getvalue(RowIdx(0), ColIdx(3)) == "100"

    let er = db.exec(SqlText("SELECT link_type, instance_id, life FROM verso_entity WHERE mutation_id = $1"), [m.id])
    check er.ntuples == 1
    check er.getvalue(RowIdx(0), ColIdx(0)) == "Person"
    check er.getvalue(RowIdx(0), ColIdx(1)) == "abc"

    let dr = db.exec(SqlText("SELECT knot, value, op, life FROM verso_delta WHERE mutation_id = $1"), [m.id])
    check dr.ntuples == 1
    check dr.getvalue(RowIdx(0), ColIdx(0)) == "name"
    check dr.getvalue(RowIdx(0), ColIdx(1)) == "Alice"

  test "query nonexistent returns 0 rows":
    let r = db.exec(SqlText("SELECT * FROM verso_mutation WHERE id = $1"), ["nope"])
    check r.ntuples == 0

  test "parent chain":
    var m1 = Mutation(parent: "", actor: "admin", timestamp: 100,
                      plan_version: 1, space: "home", partition: pData,
                      entities: @[entity("Person", "abc")],
                      deltas: @[delta_add("name", "Alice")])
    stamp(m1)
    discard db.exec(SqlText("INSERT INTO verso_mutation VALUES ($1,$2,$3,$4,$5,$6,$7)"),
            [m1.id, m1.parent, m1.actor, $m1.timestamp, $m1.plan_version, m1.space, $ord(m1.partition)])

    var m2 = Mutation(parent: m1.id, actor: "admin", timestamp: 200,
                      plan_version: 1, space: "home", partition: pData,
                      entities: @[entity("Person", "abc")],
                      deltas: @[delta_add("name", "Bob")])
    stamp(m2)
    discard db.exec(SqlText("INSERT INTO verso_mutation VALUES ($1,$2,$3,$4,$5,$6,$7)"),
            [m2.id, m2.parent, m2.actor, $m2.timestamp, $m2.plan_version, m2.space, $ord(m2.partition)])

    let cnt = db.exec(SqlText("SELECT COUNT(*) FROM verso_mutation"))
    check cnt.getvalue(RowIdx(0), ColIdx(0)) == "2"

    let r = db.exec(SqlText("SELECT parent FROM verso_mutation WHERE id = $1"), [m2.id])
    check r.getvalue(RowIdx(0), ColIdx(0)) == m1.id

  test "all Life states":
    var m = Mutation(parent: "", actor: "admin", timestamp: 999,
                     plan_version: 42, space: "test", partition: pMesh,
                     entities: @[entity("A", "a1", Life.Smash)],
                     deltas: @[Delta(knot: "x", value: "1", op: doRemove, life: Life.Gone)])
    stamp(m)
    discard db.exec(SqlText("INSERT INTO verso_mutation VALUES ($1,$2,$3,$4,$5,$6,$7)"),
            [m.id, m.parent, m.actor, $m.timestamp, $m.plan_version, m.space, $ord(m.partition)])
    for e in m.entities:
      discard db.exec(SqlText("INSERT INTO verso_entity VALUES ($1,$2,$3,$4)"),
              [m.id, e.link_type, e.instance_id, $ord(e.life)])
    for d in m.deltas:
      discard db.exec(SqlText("INSERT INTO verso_delta VALUES ($1,$2,$3,$4,$5)"),
              [m.id, d.knot, d.value, $ord(d.op), $ord(d.life)])

    let er = db.exec(SqlText("SELECT life FROM verso_entity WHERE mutation_id = $1"), [m.id])
    check er.getvalue(RowIdx(0), ColIdx(0)) == $ord(Life.Smash)

    let dr = db.exec(SqlText("SELECT life FROM verso_delta WHERE mutation_id = $1"), [m.id])
    check dr.getvalue(RowIdx(0), ColIdx(0)) == $ord(Life.Gone)

    let mr = db.exec(SqlText("SELECT partition FROM verso_mutation WHERE id = $1"), [m.id])
    check mr.getvalue(RowIdx(0), ColIdx(0)) == $ord(pMesh)
