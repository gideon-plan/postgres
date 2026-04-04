{.experimental: "strictFuncs".}
## Unit tests for distinct types and error types (no server required).

import std/unittest

import postgres/api
import postgres/ffi

# -----------------------------------------------------------------------
# SqlText
# -----------------------------------------------------------------------

suite "SqlText":
  test "construct from string literal":
    let s = SqlText("SELECT 1")
    check $s == "SELECT 1"

  test "construct from empty string":
    let s = SqlText("")
    check $s == ""

  test "equality of identical values":
    let a = SqlText("SELECT 1")
    let b = SqlText("SELECT 1")
    check a == b

  test "inequality of different values":
    let a = SqlText("SELECT 1")
    let b = SqlText("SELECT 2")
    check a != b

  test "len returns string length":
    check SqlText("abc").len == 3
    check SqlText("").len == 0
    check SqlText("SELECT count(*) FROM t").len == 22

  test "dollar converts to string":
    let s = SqlText("DROP TABLE IF EXISTS t")
    let asStr: string = $s
    check asStr == "DROP TABLE IF EXISTS t"

  test "multiline SQL":
    let s = SqlText("""
      SELECT a, b, c
      FROM table1
      WHERE a > 10
    """)
    check s.len > 0
    check $s != ""

  test "SQL with special characters":
    let s = SqlText("SELECT 'it''s a test'")
    check $s == "SELECT 'it''s a test'"

  test "SQL with unicode":
    let s = SqlText("SELECT 'cafe\u0301'")
    check s.len > 0

# -----------------------------------------------------------------------
# StmtName
# -----------------------------------------------------------------------

suite "StmtName":
  test "construct from string literal":
    let s = StmtName("my_stmt")
    check $s == "my_stmt"

  test "construct from empty string":
    let s = StmtName("")
    check $s == ""

  test "equality of identical values":
    let a = StmtName("stmt1")
    let b = StmtName("stmt1")
    check a == b

  test "inequality of different values":
    let a = StmtName("stmt1")
    let b = StmtName("stmt2")
    check a != b

  test "len returns string length":
    check StmtName("abc").len == 3
    check StmtName("").len == 0

  test "dollar converts to string":
    let s = StmtName("prepared_query")
    let asStr: string = $s
    check asStr == "prepared_query"

  test "name with underscores and digits":
    let s = StmtName("stmt_42_v2")
    check $s == "stmt_42_v2"
    check s.len == 10

# -----------------------------------------------------------------------
# RowIdx
# -----------------------------------------------------------------------

suite "RowIdx":
  test "construct from zero":
    let r = RowIdx(0)
    check $r == "0"

  test "construct from positive int":
    let r = RowIdx(42)
    check $r == "42"

  test "equality of identical values":
    let a = RowIdx(5)
    let b = RowIdx(5)
    check a == b

  test "inequality of different values":
    let a = RowIdx(0)
    let b = RowIdx(1)
    check a != b

  test "dollar converts to string":
    let r = RowIdx(99)
    let asStr: string = $r
    check asStr == "99"

  test "large index":
    let r = RowIdx(1_000_000)
    check $r == "1000000"

# -----------------------------------------------------------------------
# ColIdx
# -----------------------------------------------------------------------

suite "ColIdx":
  test "construct from zero":
    let c = ColIdx(0)
    check $c == "0"

  test "construct from positive int":
    let c = ColIdx(7)
    check $c == "7"

  test "equality of identical values":
    let a = ColIdx(3)
    let b = ColIdx(3)
    check a == b

  test "inequality of different values":
    let a = ColIdx(0)
    let b = ColIdx(1)
    check a != b

  test "dollar converts to string":
    let c = ColIdx(15)
    let asStr: string = $c
    check asStr == "15"

  test "large index":
    let c = ColIdx(500)
    check $c == "500"

# -----------------------------------------------------------------------
# PGError
# -----------------------------------------------------------------------

suite "PGError":
  test "construct with message":
    let err = newException(PGError, "connection refused")
    check err.msg == "connection refused"

  test "construct with empty message":
    let err = newException(PGError, "")
    check err.msg == ""

  test "sqlstate field defaults to empty":
    let err = newException(PGError, "some error")
    check err.sqlstate == ""

  test "sqlstate field can be set":
    var err = newException(PGError, "duplicate key")
    err.sqlstate = "23505"
    check err.sqlstate == "23505"
    check err.msg == "duplicate key"

  test "sqlstate field can be modified":
    var err = newException(PGError, "error")
    err.sqlstate = "42P01"
    check err.sqlstate == "42P01"
    err.sqlstate = "42000"
    check err.sqlstate == "42000"

  test "inherits from IOError":
    let err = newException(PGError, "io problem")
    check err of IOError

  test "inherits from CatchableError":
    let err = newException(PGError, "catchable")
    check err of CatchableError

  test "can be raised and caught as PGError":
    var caught = false
    try:
      var e = newException(PGError, "test raise")
      e.sqlstate = "XX000"
      raise e
    except PGError as e:
      caught = true
      check e.msg == "test raise"
      check e.sqlstate == "XX000"
    check caught

  test "can be caught as IOError":
    var caught = false
    try:
      raise newException(PGError, "io catch")
    except IOError:
      caught = true
    check caught

# -----------------------------------------------------------------------
# Distinct type cross-type non-equality
# -----------------------------------------------------------------------

suite "distinct type safety":
  test "SqlText and StmtName are not interchangeable":
    # These are distinct types; they should not be assignable.
    # This test verifies the $ conversion produces expected strings
    # while the types remain distinct.
    let sql = SqlText("SELECT 1")
    let stmt = StmtName("SELECT 1")
    # Same underlying string but different types.
    check $sql == $stmt
    # Type system prevents: sql == stmt (compile error).

  test "RowIdx and ColIdx are not interchangeable":
    let row = RowIdx(0)
    let col = ColIdx(0)
    # Same underlying int but different types.
    check $row == $col
    # Type system prevents: row == col (compile error).

# -----------------------------------------------------------------------
# FFI enum coverage
# -----------------------------------------------------------------------

suite "ffi enum values":
  test "ConnStatusType range":
    check ord(CONNECTION_OK) == 0
    check ord(CONNECTION_BAD) == 1
    check ord(CONNECTION_STARTED) == 2
    check ord(CONNECTION_MADE) == 3
    check ord(CONNECTION_AWAITING_RESPONSE) == 4
    check ord(CONNECTION_AUTH_OK) == 5
    check ord(CONNECTION_SETENV) == 6
    check ord(CONNECTION_SSL_STARTUP) == 7
    check ord(CONNECTION_NEEDED) == 8
    check ord(CONNECTION_CHECK_WRITABLE) == 9
    check ord(CONNECTION_CONSUME) == 10
    check ord(CONNECTION_GSS_STARTUP) == 11
    check ord(CONNECTION_CHECK_TARGET) == 12
    check ord(CONNECTION_CHECK_STANDBY) == 13
    check ord(CONNECTION_ALLOCATED) == 14
    check ord(CONNECTION_AUTHENTICATING) == 15

  test "ExecStatusType range":
    check ord(PGRES_EMPTY_QUERY) == 0
    check ord(PGRES_COMMAND_OK) == 1
    check ord(PGRES_TUPLES_OK) == 2
    check ord(PGRES_COPY_OUT) == 3
    check ord(PGRES_COPY_IN) == 4
    check ord(PGRES_BAD_RESPONSE) == 5
    check ord(PGRES_NONFATAL_ERROR) == 6
    check ord(PGRES_FATAL_ERROR) == 7
    check ord(PGRES_COPY_BOTH) == 8
    check ord(PGRES_SINGLE_TUPLE) == 9
    check ord(PGRES_PIPELINE_SYNC) == 10
    check ord(PGRES_PIPELINE_ABORTED) == 11
    check ord(PGRES_TUPLES_CHUNK) == 12

  test "PGTransactionStatusType range":
    check ord(PQTRANS_IDLE) == 0
    check ord(PQTRANS_ACTIVE) == 1
    check ord(PQTRANS_INTRANS) == 2
    check ord(PQTRANS_INERROR) == 3
    check ord(PQTRANS_UNKNOWN) == 4

  test "PGVerbosity range":
    check ord(PQERRORS_TERSE) == 0
    check ord(PQERRORS_DEFAULT) == 1
    check ord(PQERRORS_VERBOSE) == 2
    check ord(PQERRORS_SQLSTATE) == 3

  test "PGContextVisibility range":
    check ord(PQSHOW_CONTEXT_NEVER) == 0
    check ord(PQSHOW_CONTEXT_ERRORS) == 1
    check ord(PQSHOW_CONTEXT_ALWAYS) == 2

  test "PGPing range":
    check ord(PQPING_OK) == 0
    check ord(PQPING_REJECT) == 1
    check ord(PQPING_NO_RESPONSE) == 2
    check ord(PQPING_NO_ATTEMPT) == 3

  test "PGpipelineStatus range":
    check ord(PQ_PIPELINE_OFF) == 0
    check ord(PQ_PIPELINE_ON) == 1
    check ord(PQ_PIPELINE_ABORTED) == 2

  test "PGauthData range":
    check ord(PQAUTHDATA_PROMPT_OAUTH_DEVICE) == 0
    check ord(PQAUTHDATA_OAUTH_BEARER_TOKEN) == 1

  test "PostgresPollingStatusType range":
    check ord(PGRES_POLLING_FAILED) == 0
    check ord(PGRES_POLLING_READING) == 1
    check ord(PGRES_POLLING_WRITING) == 2
    check ord(PGRES_POLLING_OK) == 3
    check ord(PGRES_POLLING_ACTIVE) == 4

# -----------------------------------------------------------------------
# FFI constants and utility functions
# -----------------------------------------------------------------------

suite "ffi constants and utilities":
  test "InvalidOid is zero":
    check InvalidOid == 0'u32

  test "Oid is uint32":
    let o: Oid = 12345'u32
    check o == 12345'u32

  test "PQresStatus for all ExecStatusType values":
    check $PQresStatus(PGRES_EMPTY_QUERY) == "PGRES_EMPTY_QUERY"
    check $PQresStatus(PGRES_COMMAND_OK) == "PGRES_COMMAND_OK"
    check $PQresStatus(PGRES_TUPLES_OK) == "PGRES_TUPLES_OK"
    check $PQresStatus(PGRES_COPY_OUT) == "PGRES_COPY_OUT"
    check $PQresStatus(PGRES_COPY_IN) == "PGRES_COPY_IN"
    check $PQresStatus(PGRES_BAD_RESPONSE) == "PGRES_BAD_RESPONSE"
    check $PQresStatus(PGRES_NONFATAL_ERROR) == "PGRES_NONFATAL_ERROR"
    check $PQresStatus(PGRES_FATAL_ERROR) == "PGRES_FATAL_ERROR"

  test "PQlibVersion returns positive":
    check PQlibVersion() > 0

  test "PQisthreadsafe returns 1":
    check PQisthreadsafe() == 1

  test "pg_char_to_encoding UTF8":
    let enc = pg_char_to_encoding("UTF8".cstring)
    check enc >= 0

  test "pg_encoding_to_char round-trip":
    let enc = pg_char_to_encoding("UTF8".cstring)
    let name = $pg_encoding_to_char(enc)
    check name == "UTF8"

  test "pg_char_to_encoding SQL_ASCII":
    let enc = pg_char_to_encoding("SQL_ASCII".cstring)
    check enc == 0

  test "pg_char_to_encoding invalid returns -1":
    let enc = pg_char_to_encoding("NOT_AN_ENCODING".cstring)
    check enc == -1
