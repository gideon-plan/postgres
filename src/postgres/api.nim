## High-level PostgreSQL API wrapping libpq.

import basis/code/throw

import postgres/ffi

standard_pragmas()

raises_error(pg_err, [IOError], [])

# -----------------------------------------------------------------------
# Types
# -----------------------------------------------------------------------

type
  PGError* = object of IOError
    ## PostgreSQL error.
    sqlstate*: string

  PGDatabase* = object
    conn: PGconn

  PGQueryResult* = object
    res: PGresult

# -----------------------------------------------------------------------
# PGDatabase
# -----------------------------------------------------------------------

proc open*(conninfo: string): PGDatabase {.pg_err.} =
  ## Connect to a PostgreSQL server.
  let conn = PQconnectdb(conninfo.cstring)
  if conn.isNil:
    raise newException(PGError, "PQconnectdb returned nil")
  if PQstatus(conn) != CONNECTION_OK:
    let msg = $PQerrorMessage(conn)
    PQfinish(conn)
    raise newException(PGError, msg)
  PGDatabase(conn: conn)

proc close*(db: var PGDatabase) {.pg_err.} =
  ## Close the connection.
  if not db.conn.isNil:
    PQfinish(db.conn)
    db.conn = nil

proc raw*(db: PGDatabase): PGconn {.ok_inline.} =
  ## Access the underlying PGconn.
  db.conn

# -----------------------------------------------------------------------
# PGQueryResult
# -----------------------------------------------------------------------

proc check_result(conn: PGconn; res: PGresult): PGQueryResult {.pg_err.} =
  if res.isNil:
    raise newException(PGError, $PQerrorMessage(conn))
  let status = PQresultStatus(res)
  if status == PGRES_FATAL_ERROR:
    let msg = $PQresultErrorMessage(res)
    let sqlstate_raw = PQresultErrorField(res, 'C'.cint)
    var sqlstate = ""
    if not sqlstate_raw.isNil:
      sqlstate = $sqlstate_raw
    PQclear(res)
    var err = newException(PGError, msg)
    err.sqlstate = sqlstate
    raise err
  PGQueryResult(res: res)

proc clear*(r: var PGQueryResult) {.pg_err.} =
  ## Free the result.
  if not r.res.isNil:
    PQclear(r.res)
    r.res = nil

proc raw*(r: PGQueryResult): PGresult {.ok_inline.} =
  r.res

proc status*(r: PGQueryResult): ExecStatusType {.ok.} =
  PQresultStatus(r.res)

proc ntuples*(r: PGQueryResult): int {.ok.} =
  int(PQntuples(r.res))

proc nfields*(r: PGQueryResult): int {.ok.} =
  int(PQnfields(r.res))

proc fname*(r: PGQueryResult; col: int): string {.ok.} =
  $PQfname(r.res, cint(col))

proc ftype*(r: PGQueryResult; col: int): Oid {.ok.} =
  PQftype(r.res, cint(col))

proc getvalue*(r: PGQueryResult; row, col: int): string {.ok.} =
  $PQgetvalue(r.res, cint(row), cint(col))

proc getlength*(r: PGQueryResult; row, col: int): int {.ok.} =
  int(PQgetlength(r.res, cint(row), cint(col)))

proc getisnull*(r: PGQueryResult; row, col: int): bool {.ok.} =
  PQgetisnull(r.res, cint(row), cint(col)) == 1

proc cmd_status*(r: PGQueryResult): string {.ok.} =
  $PQcmdStatus(r.res)

proc cmd_tuples*(r: PGQueryResult): string {.ok.} =
  $PQcmdTuples(r.res)

# -----------------------------------------------------------------------
# Query execution
# -----------------------------------------------------------------------

proc exec*(db: PGDatabase; sql: string): PGQueryResult {.pg_err.} =
  ## Execute a simple query.
  check_result(db.conn, PQexec(db.conn, sql.cstring))

proc exec*(db: PGDatabase; sql: string; params: openArray[string]): PGQueryResult {.pg_err.} =
  ## Execute a parameterized query.
  var c_params = newSeq[cstring](params.len)
  for i in 0 ..< params.len:
    c_params[i] = params[i].cstring
  let param_ptr = if params.len > 0: addr c_params[0] else: nil
  check_result(db.conn, PQexecParams(
    db.conn, sql.cstring, cint(params.len),
    nil, param_ptr, nil, nil, 0
  ))

proc exec_with_nulls*(db: PGDatabase; sql: string;
                      params: openArray[string];
                      nulls: openArray[bool]): PGQueryResult {.pg_err.} =
  ## Execute a parameterized query with explicit NULL handling.
  var c_params = newSeq[cstring](params.len)
  for i in 0 ..< params.len:
    if nulls[i]:
      c_params[i] = nil
    else:
      c_params[i] = params[i].cstring
  let param_ptr = if params.len > 0: addr c_params[0] else: nil
  check_result(db.conn, PQexecParams(
    db.conn, sql.cstring, cint(params.len),
    nil, param_ptr, nil, nil, 0
  ))

# -----------------------------------------------------------------------
# Prepared statements
# -----------------------------------------------------------------------

proc prepare*(db: PGDatabase; name, sql: string; nparams: int = 0): PGQueryResult {.pg_err.} =
  ## Prepare a named statement.
  check_result(db.conn, PQprepare(db.conn, name.cstring, sql.cstring,
                                   cint(nparams), nil))

proc exec_prepared*(db: PGDatabase; name: string;
                    params: openArray[string]): PGQueryResult {.pg_err.} =
  ## Execute a prepared statement.
  var c_params = newSeq[cstring](params.len)
  for i in 0 ..< params.len:
    c_params[i] = params[i].cstring
  let param_ptr = if params.len > 0: addr c_params[0] else: nil
  check_result(db.conn, PQexecPrepared(
    db.conn, name.cstring, cint(params.len),
    param_ptr, nil, nil, 0
  ))

# -----------------------------------------------------------------------
# Transactions
# -----------------------------------------------------------------------

proc begin*(db: PGDatabase) {.pg_err.} =
  var r = db.exec("BEGIN")
  r.clear()

proc commit*(db: PGDatabase) {.pg_err.} =
  var r = db.exec("COMMIT")
  r.clear()

proc rollback*(db: PGDatabase) {.pg_err.} =
  var r = db.exec("ROLLBACK")
  r.clear()

# -----------------------------------------------------------------------
# Connection info
# -----------------------------------------------------------------------

proc database*(db: PGDatabase): string {.ok.} =
  $PQdb(db.conn)

proc user*(db: PGDatabase): string {.ok.} =
  $PQuser(db.conn)

proc host*(db: PGDatabase): string {.ok.} =
  $PQhost(db.conn)

proc port*(db: PGDatabase): string {.ok.} =
  $PQport(db.conn)

proc server_version*(db: PGDatabase): int {.ok.} =
  int(PQserverVersion(db.conn))

proc error_message*(db: PGDatabase): string {.ok.} =
  $PQerrorMessage(db.conn)

proc transaction_status*(db: PGDatabase): PGTransactionStatusType {.ok.} =
  PQtransactionStatus(db.conn)

# -----------------------------------------------------------------------
# COPY support
# -----------------------------------------------------------------------

proc put_copy_data*(db: PGDatabase; data: string): int {.pg_err.} =
  int(PQputCopyData(db.conn, data.cstring, cint(data.len)))

proc put_copy_end*(db: PGDatabase; errormsg: string = ""): int {.pg_err.} =
  let msg = if errormsg.len > 0: errormsg.cstring else: nil
  int(PQputCopyEnd(db.conn, msg))

proc get_copy_data*(db: PGDatabase; async: bool = false): (int, string) {.pg_err.} =
  var buf: cstring
  let nbytes = PQgetCopyData(db.conn, addr buf, cint(ord(async)))
  if nbytes > 0 and not buf.isNil:
    let data = $buf
    PQfreemem(buf)
    (int(nbytes), data)
  else:
    (int(nbytes), "")
