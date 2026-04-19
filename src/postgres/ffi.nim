{.experimental: "strictFuncs".}
## PostgreSQL libpq C API bindings.
##
## Source: libpq-fe.h from PostgreSQL 18 (REL_18_BETA1).
## 174 PQ functions bound.

import segfaults
import basis/code/throw

standard_pragmas()

{.push cdecl, header: "<libpq-fe.h>".}

#=======================================================================================================================
#== TYPES FROM POSTGRES_EXT.H ==========================================================================================
#=======================================================================================================================

type Oid* = uint32

const InvalidOid*: Oid = 0

#=======================================================================================================================
#== ENUMS ==============================================================================================================
#=======================================================================================================================

type
  ConnStatusKind* {.importc: "ConnStatusKind".} = enum
    CONNECTION_OK = 0
    CONNECTION_BAD = 1
    CONNECTION_STARTED = 2
    CONNECTION_MADE = 3
    CONNECTION_AWAITING_RESPONSE = 4
    CONNECTION_AUTH_OK = 5
    CONNECTION_SETENV = 6
    CONNECTION_SSL_STARTUP = 7
    CONNECTION_NEEDED = 8
    CONNECTION_CHECK_WRITABLE = 9
    CONNECTION_CONSUME = 10
    CONNECTION_GSS_STARTUP = 11
    CONNECTION_CHECK_TARGET = 12
    CONNECTION_CHECK_STANDBY = 13
    CONNECTION_ALLOCATED = 14
    CONNECTION_AUTHENTICATING = 15

  PostgresPollingStatusKind* {.importc: "PostgresPollingStatusKind".} = enum
    PGRES_POLLING_FAILED = 0
    PGRES_POLLING_READING = 1
    PGRES_POLLING_WRITING = 2
    PGRES_POLLING_OK = 3
    PGRES_POLLING_ACTIVE = 4

  ExecStatusKind* {.importc: "ExecStatusKind".} = enum
    PGRES_EMPTY_QUERY = 0
    PGRES_COMMAND_OK = 1
    PGRES_TUPLES_OK = 2
    PGRES_COPY_OUT = 3
    PGRES_COPY_IN = 4
    PGRES_BAD_RESPONSE = 5
    PGRES_NONFATAL_ERROR = 6
    PGRES_FATAL_ERROR = 7
    PGRES_COPY_BOTH = 8
    PGRES_SINGLE_TUPLE = 9
    PGRES_PIPELINE_SYNC = 10
    PGRES_PIPELINE_ABORTED = 11
    PGRES_TUPLES_CHUNK = 12

  PGTransactionStatusKind* {.importc: "PGTransactionStatusKind".} = enum
    PQTRANS_IDLE = 0
    PQTRANS_ACTIVE = 1
    PQTRANS_INTRANS = 2
    PQTRANS_INERROR = 3
    PQTRANS_UNKNOWN = 4

  PGVerbosity* {.importc: "PGVerbosity".} = enum
    PQERRORS_TERSE = 0
    PQERRORS_DEFAULT = 1
    PQERRORS_VERBOSE = 2
    PQERRORS_SQLSTATE = 3

  PGContextVisibility* {.importc: "PGContextVisibility".} = enum
    PQSHOW_CONTEXT_NEVER = 0
    PQSHOW_CONTEXT_ERRORS = 1
    PQSHOW_CONTEXT_ALWAYS = 2

  PGPing* {.importc: "PGPing".} = enum
    PQPING_OK = 0
    PQPING_REJECT = 1
    PQPING_NO_RESPONSE = 2
    PQPING_NO_ATTEMPT = 3

  PGpipelineStatus* {.importc: "PGpipelineStatus".} = enum
    PQ_PIPELINE_OFF = 0
    PQ_PIPELINE_ON = 1
    PQ_PIPELINE_ABORTED = 2

  PGauthData* {.importc: "PGauthData".} = enum
    PQAUTHDATA_PROMPT_OAUTH_DEVICE = 0
    PQAUTHDATA_OAUTH_BEARER_TOKEN = 1

#=======================================================================================================================
#== OPAQUE POINTER TYPES ===============================================================================================
#=======================================================================================================================

type
  PGconn* = ptr object
  PGcancelConn* = ptr object
  PGresult* = ptr object
  PGcancel* = ptr object

#=======================================================================================================================
#== STRUCT TYPES =======================================================================================================
#=======================================================================================================================

type
  PGnotify* {.importc: "PGnotify", bycopy.} = object
    relname*: cstring
    be_pid*: cint
    extra*: cstring
    next*: ptr PGnotify

  PQconninfoOption* {.importc: "PQconninfoOption", bycopy.} = object
    keyword*: cstring
    envvar*: cstring
    compiled*: cstring
    val*: cstring
    label*: cstring
    dispchar*: cstring
    dispsize*: cint

  PGresAttDesc* {.importc: "PGresAttDesc", bycopy.} = object
    name*: cstring
    tableid*: Oid
    columnid*: cint
    format*: cint
    typid*: Oid
    typlen*: cint
    atttypmod*: cint

  PQArgBlock* {.importc: "PQArgBlock", bycopy.} = object
    len*: cint
    isint*: cint

#=======================================================================================================================
#== CALLBACK TYPES =====================================================================================================
#=======================================================================================================================

type
  PQnoticeReceiver* = proc(arg: pointer; res: PGresult) {.cdecl.}
  PQnoticeProcessor* = proc(arg: pointer; message: cstring) {.cdecl.}
  pgthreadlock_t* = proc(acquire: cint) {.cdecl.}
  PQauthDataHook_type* = proc(typ: PGauthData; conn: PGconn; data: pointer): cint {.cdecl.}
  PQsslKeyPassHook_OpenSSL_type* = proc(buf: cstring; size: cint; conn: PGconn): cint {.cdecl.}

type pg_usec_time_t* = int64

#=======================================================================================================================
#== CONNECTION FUNCTIONS ===============================================================================================
#=======================================================================================================================

proc PQconnectStart*(conninfo: cstring): PGconn {.importc.}
proc PQconnectStartParams*(keywords, values: ptr cstring; expand_dbname: cint): PGconn {.importc.}
proc PQconnectPoll*(conn: PGconn): PostgresPollingStatusKind {.importc.}
proc PQconnectdb*(conninfo: cstring): PGconn {.importc.}
proc PQconnectdbParams*(keywords, values: ptr cstring; expand_dbname: cint): PGconn {.importc.}
proc PQsetdbLogin*(pghost, pgport, pgoptions, pgtty, dbName, login, pwd: cstring): PGconn {.importc.}
proc PQfinish*(conn: PGconn) {.importc.}
proc PQconndefaults*(): ptr PQconninfoOption {.importc.}
proc PQconninfoParse*(conninfo: cstring; errmsg: ptr cstring): ptr PQconninfoOption {.importc.}
proc PQconninfo*(conn: PGconn): ptr PQconninfoOption {.importc.}
proc PQconninfoFree*(connOptions: ptr PQconninfoOption) {.importc.}
proc PQresetStart*(conn: PGconn): cint {.importc.}
proc PQresetPoll*(conn: PGconn): PostgresPollingStatusKind {.importc.}
proc PQreset*(conn: PGconn) {.importc.}

#=======================================================================================================================
#== CANCEL FUNCTIONS (NEW ASYNC API) ===================================================================================
#=======================================================================================================================

proc PQcancelCreate*(conn: PGconn): PGcancelConn {.importc.}
proc PQcancelStart*(cancelConn: PGcancelConn): cint {.importc.}
proc PQcancelBlocking*(cancelConn: PGcancelConn): cint {.importc.}
proc PQcancelPoll*(cancelConn: PGcancelConn): PostgresPollingStatusKind {.importc.}
proc PQcancelStatus*(cancelConn: PGcancelConn): ConnStatusKind {.importc.}
proc PQcancelSocket*(cancelConn: PGcancelConn): cint {.importc.}
proc PQcancelErrorMessage*(cancelConn: PGcancelConn): cstring {.importc.}
proc PQcancelReset*(cancelConn: PGcancelConn) {.importc.}
proc PQcancelFinish*(cancelConn: PGcancelConn) {.importc.}

#=======================================================================================================================
#== CANCEL FUNCTIONS (LEGACY) ==========================================================================================
#=======================================================================================================================

proc PQgetCancel*(conn: PGconn): PGcancel {.importc.}
proc PQfreeCancel*(cancel: PGcancel) {.importc.}
proc PQcancel*(cancel: PGcancel; errbuf: cstring; errbufsize: cint): cint {.importc.}
proc PQrequestCancel*(conn: PGconn): cint {.importc.}

#=======================================================================================================================
#== CONNECTION INFO ACCESSORS ==========================================================================================
#=======================================================================================================================

proc PQdb*(conn: PGconn): cstring {.importc.}
proc PQservice*(conn: PGconn): cstring {.importc.}
proc PQuser*(conn: PGconn): cstring {.importc.}
proc PQpass*(conn: PGconn): cstring {.importc.}
proc PQhost*(conn: PGconn): cstring {.importc.}
proc PQhostaddr*(conn: PGconn): cstring {.importc.}
proc PQport*(conn: PGconn): cstring {.importc.}
proc PQtty*(conn: PGconn): cstring {.importc.}
proc PQoptions*(conn: PGconn): cstring {.importc.}
proc PQstatus*(conn: PGconn): ConnStatusKind {.importc.}
proc PQtransactionStatus*(conn: PGconn): PGTransactionStatusKind {.importc.}
proc PQparameterStatus*(conn: PGconn; paramName: cstring): cstring {.importc.}
proc PQprotocolVersion*(conn: PGconn): cint {.importc.}
proc PQfullProtocolVersion*(conn: PGconn): cint {.importc.}
proc PQserverVersion*(conn: PGconn): cint {.importc.}
proc PQerrorMessage*(conn: PGconn): cstring {.importc.}
proc PQsocket*(conn: PGconn): cint {.importc.}
proc PQbackendPID*(conn: PGconn): cint {.importc.}
proc PQpipelineStatus*(conn: PGconn): PGpipelineStatus {.importc.}
proc PQconnectionNeedsPassword*(conn: PGconn): cint {.importc.}
proc PQconnectionUsedPassword*(conn: PGconn): cint {.importc.}
proc PQconnectionUsedGSSAPI*(conn: PGconn): cint {.importc.}
proc PQclientEncoding*(conn: PGconn): cint {.importc.}
proc PQsetClientEncoding*(conn: PGconn; encoding: cstring): cint {.importc.}

#=======================================================================================================================
#== SSL FUNCTIONS ======================================================================================================
#=======================================================================================================================

proc PQsslInUse*(conn: PGconn): cint {.importc.}
proc PQsslStruct*(conn: PGconn; struct_name: cstring): pointer {.importc.}
proc PQsslAttribute*(conn: PGconn; attribute_name: cstring): cstring {.importc.}
proc PQsslAttributeNames*(conn: PGconn): ptr cstring {.importc.}
proc PQgetssl*(conn: PGconn): pointer {.importc.}
proc PQinitSSL*(do_init: cint) {.importc.}
proc PQinitOpenSSL*(do_ssl, do_crypto: cint) {.importc.}

#=======================================================================================================================
#== GSS FUNCTIONS ======================================================================================================
#=======================================================================================================================

proc PQgssEncInUse*(conn: PGconn): cint {.importc.}
proc PQgetgssctx*(conn: PGconn): pointer {.importc.}

#=======================================================================================================================
#== ERROR VERBOSITY ====================================================================================================
#=======================================================================================================================

proc PQsetErrorVerbosity*(conn: PGconn; verbosity: PGVerbosity): PGVerbosity {.importc.}
proc PQsetErrorContextVisibility*(conn: PGconn; show_context: PGContextVisibility): PGContextVisibility {.importc.}

#=======================================================================================================================
#== NOTICE HANDLING ====================================================================================================
#=======================================================================================================================

proc PQsetNoticeReceiver*(conn: PGconn; fn: PQnoticeReceiver; arg: pointer): PQnoticeReceiver {.importc.}
proc PQsetNoticeProcessor*(conn: PGconn; fn: PQnoticeProcessor; arg: pointer): PQnoticeProcessor {.importc.}

#=======================================================================================================================
#== THREAD LOCK ========================================================================================================
#=======================================================================================================================

proc PQregisterThreadLock*(newhandler: pgthreadlock_t): pgthreadlock_t {.importc.}

#=======================================================================================================================
#== TRACE ==============================================================================================================
#=======================================================================================================================

proc PQtrace*(conn: PGconn; debug_port: pointer) {.importc.}  # FILE*
proc PQuntrace*(conn: PGconn) {.importc.}
proc PQsetTraceFlags*(conn: PGconn; flags: cint) {.importc.}

#=======================================================================================================================
#== QUERY EXECUTION (SYNCHRONOUS) ======================================================================================
#=======================================================================================================================

proc PQexec*(conn: PGconn; query: cstring): PGresult {.importc.}
proc PQexecParams*(conn: PGconn; command: cstring; nParams: cint;
                   paramTypes: ptr Oid; paramValues: ptr cstring;
                   paramLengths: ptr cint; paramFormats: ptr cint;
                   resultFormat: cint): PGresult {.importc.}
proc PQprepare*(conn: PGconn; stmtName, query: cstring; nParams: cint;
                paramTypes: ptr Oid): PGresult {.importc.}
proc PQexecPrepared*(conn: PGconn; stmtName: cstring; nParams: cint;
                     paramValues: ptr cstring; paramLengths: ptr cint;
                     paramFormats: ptr cint; resultFormat: cint): PGresult {.importc.}

#=======================================================================================================================
#== QUERY EXECUTION (ASYNCHRONOUS) =====================================================================================
#=======================================================================================================================

proc PQsendQuery*(conn: PGconn; query: cstring): cint {.importc.}
proc PQsendQueryParams*(conn: PGconn; command: cstring; nParams: cint;
                        paramTypes: ptr Oid; paramValues: ptr cstring;
                        paramLengths: ptr cint; paramFormats: ptr cint;
                        resultFormat: cint): cint {.importc.}
proc PQsendPrepare*(conn: PGconn; stmtName, query: cstring; nParams: cint;
                    paramTypes: ptr Oid): cint {.importc.}
proc PQsendQueryPrepared*(conn: PGconn; stmtName: cstring; nParams: cint;
                          paramValues: ptr cstring; paramLengths: ptr cint;
                          paramFormats: ptr cint; resultFormat: cint): cint {.importc.}
proc PQsetSingleRowMode*(conn: PGconn): cint {.importc.}
proc PQsetChunkedRowsMode*(conn: PGconn; chunkSize: cint): cint {.importc.}
proc PQgetResult*(conn: PGconn): PGresult {.importc.}
proc PQisBusy*(conn: PGconn): cint {.importc.}
proc PQconsumeInput*(conn: PGconn): cint {.importc.}

#=======================================================================================================================
#== PIPELINE MODE ======================================================================================================
#=======================================================================================================================

proc PQenterPipelineMode*(conn: PGconn): cint {.importc.}
proc PQexitPipelineMode*(conn: PGconn): cint {.importc.}
proc PQpipelineSync*(conn: PGconn): cint {.importc.}
proc PQsendFlushRequest*(conn: PGconn): cint {.importc.}
proc PQsendPipelineSync*(conn: PGconn): cint {.importc.}

#=======================================================================================================================
#== LISTEN/NOTIFY ======================================================================================================
#=======================================================================================================================

proc PQnotifies*(conn: PGconn): ptr PGnotify {.importc.}

#=======================================================================================================================
#== COPY ===============================================================================================================
#=======================================================================================================================

proc PQputCopyData*(conn: PGconn; buffer: cstring; nbytes: cint): cint {.importc.}
proc PQputCopyEnd*(conn: PGconn; errormsg: cstring): cint {.importc.}
proc PQgetCopyData*(conn: PGconn; buffer: ptr cstring; async: cint): cint {.importc.}

#=======================================================================================================================
#== COPY (LEGACY) ======================================================================================================
#=======================================================================================================================

proc PQgetline*(conn: PGconn; buffer: cstring; length: cint): cint {.importc.}
proc PQputline*(conn: PGconn; str: cstring): cint {.importc.}
proc PQgetlineAsync*(conn: PGconn; buffer: cstring; bufsize: cint): cint {.importc.}
proc PQputnbytes*(conn: PGconn; buffer: cstring; nbytes: cint): cint {.importc.}
proc PQendcopy*(conn: PGconn): cint {.importc.}

#=======================================================================================================================
#== MISC ===============================================================================================================
#=======================================================================================================================

proc PQsetnonblocking*(conn: PGconn; arg: cint): cint {.importc.}
proc PQisnonblocking*(conn: PGconn): cint {.importc.}
proc PQisthreadsafe*(): cint {.importc.}
proc PQping*(conninfo: cstring): PGPing {.importc.}
proc PQpingParams*(keywords, values: ptr cstring; expand_dbname: cint): PGPing {.importc.}
proc PQflush*(conn: PGconn): cint {.importc.}

#=======================================================================================================================
#== FAST PATH ==========================================================================================================
#=======================================================================================================================

proc PQfn*(conn: PGconn; fnid: cint; result_buf, result_len: ptr cint;
           result_is_int: cint; args: ptr PQArgBlock; nargs: cint): PGresult {.importc.}

#=======================================================================================================================
#== RESULT ACCESSORS ===================================================================================================
#=======================================================================================================================

proc PQresultStatus*(res: PGresult): ExecStatusKind {.importc.}
proc PQresStatus*(status: ExecStatusKind): cstring {.importc.}
proc PQresultErrorMessage*(res: PGresult): cstring {.importc.}
proc PQresultVerboseErrorMessage*(res: PGresult; verbosity: PGVerbosity;
                                  show_context: PGContextVisibility): cstring {.importc.}
proc PQresultErrorField*(res: PGresult; fieldcode: cint): cstring {.importc.}
proc PQntuples*(res: PGresult): cint {.importc.}
proc PQnfields*(res: PGresult): cint {.importc.}
proc PQbinaryTuples*(res: PGresult): cint {.importc.}
proc PQfname*(res: PGresult; field_num: cint): cstring {.importc.}
proc PQfnumber*(res: PGresult; field_name: cstring): cint {.importc.}
proc PQftable*(res: PGresult; field_num: cint): Oid {.importc.}
proc PQftablecol*(res: PGresult; field_num: cint): cint {.importc.}
proc PQfformat*(res: PGresult; field_num: cint): cint {.importc.}
proc PQftype*(res: PGresult; field_num: cint): Oid {.importc.}
proc PQfsize*(res: PGresult; field_num: cint): cint {.importc.}
proc PQfmod*(res: PGresult; field_num: cint): cint {.importc.}
proc PQcmdStatus*(res: PGresult): cstring {.importc.}
proc PQoidStatus*(res: PGresult): cstring {.importc.}
proc PQoidValue*(res: PGresult): Oid {.importc.}
proc PQcmdTuples*(res: PGresult): cstring {.importc.}
proc PQgetvalue*(res: PGresult; tup_num, field_num: cint): cstring {.importc.}
proc PQgetlength*(res: PGresult; tup_num, field_num: cint): cint {.importc.}
proc PQgetisnull*(res: PGresult; tup_num, field_num: cint): cint {.importc.}
proc PQnparams*(res: PGresult): cint {.importc.}
proc PQparamtype*(res: PGresult; param_num: cint): Oid {.importc.}

#=======================================================================================================================
#== DESCRIBE / CLOSE PREPARED ==========================================================================================
#=======================================================================================================================

proc PQdescribePrepared*(conn: PGconn; stmt: cstring): PGresult {.importc.}
proc PQdescribePortal*(conn: PGconn; portal: cstring): PGresult {.importc.}
proc PQsendDescribePrepared*(conn: PGconn; stmt: cstring): cint {.importc.}
proc PQsendDescribePortal*(conn: PGconn; portal: cstring): cint {.importc.}
proc PQclosePrepared*(conn: PGconn; stmt: cstring): PGresult {.importc.}
proc PQclosePortal*(conn: PGconn; portal: cstring): PGresult {.importc.}
proc PQsendClosePrepared*(conn: PGconn; stmt: cstring): cint {.importc.}
proc PQsendClosePortal*(conn: PGconn; portal: cstring): cint {.importc.}

#=======================================================================================================================
#== RESULT MANAGEMENT ==================================================================================================
#=======================================================================================================================

proc PQclear*(res: PGresult) {.importc.}
proc PQfreemem*(p: pointer) {.importc.}
proc PQmakeEmptyPGresult*(conn: PGconn; status: ExecStatusKind): PGresult {.importc.}
proc PQcopyResult*(src: PGresult; flags: cint): PGresult {.importc.}
proc PQsetResultAttrs*(res: PGresult; numAttributes: cint; attDescs: ptr PGresAttDesc): cint {.importc.}
proc PQresultAlloc*(res: PGresult; nBytes: csize_t): pointer {.importc.}
proc PQresultMemorySize*(res: PGresult): csize_t {.importc.}
proc PQsetvalue*(res: PGresult; tup_num, field_num: cint; value: cstring; len: cint): cint {.importc.}

#=======================================================================================================================
#== ESCAPING ===========================================================================================================
#=======================================================================================================================

proc PQescapeStringConn*(conn: PGconn; to, frm: cstring; length: csize_t;
                         error: ptr cint): csize_t {.importc.}
proc PQescapeLiteral*(conn: PGconn; str: cstring; len: csize_t): cstring {.importc.}
proc PQescapeIdentifier*(conn: PGconn; str: cstring; len: csize_t): cstring {.importc.}
proc PQescapeByteaConn*(conn: PGconn; frm: ptr uint8; from_length: csize_t;
                        to_length: ptr csize_t): ptr uint8 {.importc.}
proc PQunescapeBytea*(strtext: ptr uint8; retbuflen: ptr csize_t): ptr uint8 {.importc.}
proc PQescapeString*(to, frm: cstring; length: csize_t): csize_t {.importc.}
proc PQescapeBytea*(frm: ptr uint8; from_length: csize_t;
                    to_length: ptr csize_t): ptr uint8 {.importc.}

#=======================================================================================================================
#== PRINT ==============================================================================================================
#=======================================================================================================================

proc PQprint*(fout: pointer; res: PGresult; po: pointer) {.importc.}
proc PQdisplayTuples*(res: PGresult; fp: pointer; fillAlign: cint;
                      fieldSep: cstring; printHeader, quiet: cint) {.importc.}
proc PQprintTuples*(res: PGresult; fout: pointer; PrintAttNames,
                    TerseOutput, colWidth: cint) {.importc.}

#=======================================================================================================================
#== LARGE OBJECTS ======================================================================================================
#=======================================================================================================================

proc lo_open*(conn: PGconn; lobjId: Oid; mode: cint): cint {.importc.}
proc lo_close*(conn: PGconn; fd: cint): cint {.importc.}
proc lo_read*(conn: PGconn; fd: cint; buf: cstring; len: csize_t): cint {.importc.}
proc lo_write*(conn: PGconn; fd: cint; buf: cstring; len: csize_t): cint {.importc.}
proc lo_lseek*(conn: PGconn; fd, offset, whence: cint): cint {.importc.}
proc lo_lseek64*(conn: PGconn; fd: cint; offset: int64; whence: cint): int64 {.importc.}
proc lo_creat*(conn: PGconn; mode: cint): Oid {.importc.}
proc lo_create*(conn: PGconn; lobjId: Oid): Oid {.importc.}
proc lo_tell*(conn: PGconn; fd: cint): cint {.importc.}
proc lo_tell64*(conn: PGconn; fd: cint): int64 {.importc.}
proc lo_truncate*(conn: PGconn; fd: cint; len: csize_t): cint {.importc.}
proc lo_truncate64*(conn: PGconn; fd: cint; len: int64): cint {.importc.}
proc lo_unlink*(conn: PGconn; lobjId: Oid): cint {.importc.}
proc lo_import*(conn: PGconn; filename: cstring): Oid {.importc.}
proc lo_import_with_oid*(conn: PGconn; filename: cstring; lobjId: Oid): Oid {.importc.}
proc lo_export*(conn: PGconn; lobjId: Oid; filename: cstring): cint {.importc.}

#=======================================================================================================================
#== MISC UTILITIES =====================================================================================================
#=======================================================================================================================

proc PQlibVersion*(): cint {.importc.}
proc PQsocketPoll*(sock, forRead, forWrite: cint; end_time: pg_usec_time_t): cint {.importc.}
proc PQgetCurrentTimeUSec*(): pg_usec_time_t {.importc.}
proc PQmblen*(s: cstring; encoding: cint): cint {.importc.}
proc PQmblenBounded*(s: cstring; encoding: cint): cint {.importc.}
proc PQdsplen*(s: cstring; encoding: cint): cint {.importc.}
proc PQenv2encoding*(): cint {.importc.}

#=======================================================================================================================
#== AUTH ===============================================================================================================
#=======================================================================================================================

proc PQencryptPassword*(passwd, user: cstring): cstring {.importc.}
proc PQencryptPasswordConn*(conn: PGconn; passwd, user, algorithm: cstring): cstring {.importc.}
proc PQchangePassword*(conn: PGconn; user, passwd: cstring): PGresult {.importc.}
proc PQsetAuthDataHook*(hook: PQauthDataHook_type) {.importc.}
proc PQgetAuthDataHook*(): PQauthDataHook_type {.importc.}
proc PQdefaultAuthDataHook*(typ: PGauthData; conn: PGconn; data: pointer): cint {.importc.}

#=======================================================================================================================
#== SSL KEY PASS HOOK ==================================================================================================
#=======================================================================================================================

proc PQgetSSLKeyPassHook_OpenSSL*(): PQsslKeyPassHook_OpenSSL_type {.importc.}
proc PQsetSSLKeyPassHook_OpenSSL*(hook: PQsslKeyPassHook_OpenSSL_type) {.importc.}
proc PQdefaultSSLKeyPassHook_OpenSSL*(buf: cstring; size: cint; conn: PGconn): cint {.importc.}

#=======================================================================================================================
#== ENCODING FUNCTIONS (FROM ENCNAMES.C, DECLARED IN LIBPQ-FE.H) =======================================================
#=======================================================================================================================

proc pg_char_to_encoding*(name: cstring): cint {.importc.}
proc pg_encoding_to_char*(encoding: cint): cstring {.importc.}
proc pg_valid_server_encoding_id*(encoding: cint): cint {.importc.}

{.pop.}
