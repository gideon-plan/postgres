## FFI smoke tests (no server required).

import std/unittest

import postgres/ffi

suite "ffi smoke":
  test "PQlibVersion":
    let v = PQlibVersion()
    check v > 0

  test "PQisthreadsafe":
    check PQisthreadsafe() == 1

  test "enum values":
    check ord(CONNECTION_OK) == 0
    check ord(CONNECTION_BAD) == 1
    check ord(PGRES_COMMAND_OK) == 1
    check ord(PGRES_TUPLES_OK) == 2
    check ord(PGRES_FATAL_ERROR) == 7
    check ord(PQTRANS_IDLE) == 0
    check ord(PQPING_OK) == 0
    check ord(PQ_PIPELINE_OFF) == 0

  test "PQresStatus":
    check $PQresStatus(PGRES_COMMAND_OK) == "PGRES_COMMAND_OK"
    check $PQresStatus(PGRES_TUPLES_OK) == "PGRES_TUPLES_OK"
