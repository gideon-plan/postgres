# postgres

PostgreSQL client for Nim via libpq FFI. Supports parameterized queries, prepared statements, transactions, COPY protocol, and typed result access.

## Install

```
nimble install
```

## Usage

```nim
import postgres

var db = open("host=localhost dbname=test")
var r = db.exec(SqlText("SELECT 1 AS n"))
echo r.getvalue(RowIdx(0), ColIdx(0))
r.clear()
db.close()
```

## License

Proprietary
