## API integration tests (requires PostgreSQL server on localhost:15432).

import std/unittest

import postgres/api
import postgres/ffi

const ConnInfo = "host=127.0.0.1 port=15432 dbname=test user=test password=test"

suite "api integration":
  test "connect and disconnect":
    var db = api.open(ConnInfo)
    defer: db.close()
    check db.server_version() > 0

  test "connection info":
    var db = api.open(ConnInfo)
    defer: db.close()
    check db.database() == "test"
    check db.user() == "test"

  test "execute DDL":
    var db = api.open(ConnInfo)
    defer: db.close()
    var r1 = db.exec(SqlText("DROP TABLE IF EXISTS test_nim"))
    r1.clear()
    var r2 = db.exec(SqlText("""
      CREATE TABLE test_nim (
        id SERIAL PRIMARY KEY,
        name TEXT NOT NULL,
        value DOUBLE PRECISION
      )
    """))
    r2.clear()
    var r3 = db.exec(SqlText("DROP TABLE test_nim"))
    r3.clear()

  test "query select 1":
    var db = api.open(ConnInfo)
    defer: db.close()
    var r = db.exec(SqlText("SELECT 1 AS n"))
    defer: r.clear()
    check r.ntuples() == 1
    check r.nfields() == 1
    check r.fname(ColIdx(0)) == "n"
    check r.getvalue(RowIdx(0), ColIdx(0)) == "1"

  test "insert and select round-trip":
    var db = api.open(ConnInfo)
    defer: db.close()
    var r1 = db.exec(SqlText("DROP TABLE IF EXISTS test_rt"))
    r1.clear()
    var r2 = db.exec(SqlText("""
      CREATE TABLE test_rt (
        id INTEGER,
        name TEXT,
        val DOUBLE PRECISION
      )
    """))
    r2.clear()
    var r3 = db.exec(SqlText("INSERT INTO test_rt VALUES (1, 'alpha', 1.1), (2, 'beta', 2.2), (3, 'gamma', 3.3)"))
    r3.clear()
    var r4 = db.exec(SqlText("SELECT id, name, val FROM test_rt ORDER BY id"))
    defer: r4.clear()
    check r4.ntuples() == 3
    check r4.getvalue(RowIdx(0), ColIdx(0)) == "1"
    check r4.getvalue(RowIdx(1), ColIdx(1)) == "beta"
    check r4.getvalue(RowIdx(2), ColIdx(2)) == "3.3"
    var r5 = db.exec(SqlText("DROP TABLE test_rt"))
    r5.clear()

  test "parameterized query":
    var db = api.open(ConnInfo)
    defer: db.close()
    var r = db.exec(SqlText("SELECT $1::int + $2::int AS sum"), ["3", "4"])
    defer: r.clear()
    check r.ntuples() == 1
    check r.getvalue(RowIdx(0), ColIdx(0)) == "7"

  test "NULL handling":
    var db = api.open(ConnInfo)
    defer: db.close()
    var r = db.exec(SqlText("SELECT NULL::text AS n"))
    defer: r.clear()
    check r.getisnull(RowIdx(0), ColIdx(0))
    check r.getvalue(RowIdx(0), ColIdx(0)) == ""

  test "transaction begin/commit/rollback":
    var db = api.open(ConnInfo)
    defer: db.close()
    var r1 = db.exec(SqlText("DROP TABLE IF EXISTS test_tx"))
    r1.clear()
    var r2 = db.exec(SqlText("CREATE TABLE test_tx (id INTEGER)"))
    r2.clear()
    # Commit path
    db.begin()
    var r3 = db.exec(SqlText("INSERT INTO test_tx VALUES (1)"))
    r3.clear()
    db.commit()
    var r4 = db.exec(SqlText("SELECT count(*) FROM test_tx"))
    check r4.getvalue(RowIdx(0), ColIdx(0)) == "1"
    r4.clear()
    # Rollback path
    db.begin()
    var r5 = db.exec(SqlText("INSERT INTO test_tx VALUES (2)"))
    r5.clear()
    db.rollback()
    var r6 = db.exec(SqlText("SELECT count(*) FROM test_tx"))
    check r6.getvalue(RowIdx(0), ColIdx(0)) == "1"
    r6.clear()
    var r7 = db.exec(SqlText("DROP TABLE test_tx"))
    r7.clear()

  test "error handling":
    var db = api.open(ConnInfo)
    defer: db.close()
    var caught = false
    try:
      var r = db.exec(SqlText("SELECT * FROM nonexistent_table_xyz"))
      r.clear()
    except PGError:
      caught = true
    check caught

  test "prepared statement":
    var db = api.open(ConnInfo)
    defer: db.close()
    var r1 = db.prepare(StmtName("test_stmt"), SqlText("SELECT $1::text || $2::text AS concat"))
    r1.clear()
    var r2 = db.exec_prepared(StmtName("test_stmt"), ["hello", " world"])
    defer: r2.clear()
    check r2.getvalue(RowIdx(0), ColIdx(0)) == "hello world"

  test "type round-trips":
    var db = api.open(ConnInfo)
    defer: db.close()
    var r = db.exec(SqlText("""
      SELECT
        42::integer AS int_val,
        3.14::double precision AS float_val,
        'hello'::text AS text_val,
        true::boolean AS bool_val,
        '2026-03-15'::date AS date_val,
        'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'::uuid AS uuid_val
    """))
    defer: r.clear()
    check r.getvalue(RowIdx(0), ColIdx(0)) == "42"
    check r.getvalue(RowIdx(0), ColIdx(1)) == "3.14"
    check r.getvalue(RowIdx(0), ColIdx(2)) == "hello"
    check r.getvalue(RowIdx(0), ColIdx(3)) == "t"
    check r.getvalue(RowIdx(0), ColIdx(4)) == "2026-03-15"
    check r.getvalue(RowIdx(0), ColIdx(5)) == "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11"
