---
title: bcdock env get
---

## bcdock env get

Get details of an environment

### Synopsis

Show full details of one environment - connection endpoints (web client,
SOAP, OData v4, dev endpoint, downloads), the BC admin username, status,
and timestamps.

This does NOT return the BC admin password or the web-service access key. Use
'bcdock env credentials <env>' for those; the reveal is explicit and audited.

Output formats:
  -o table  (default) vertical key/value layout, one field per line
  -o json   the full env record from the API (use for scripting)
  -o csv    the same compact row as 'env list' (one entry)

Exit codes:
  0   ok
  3   auth failure (missing or invalid token)
  4   rate-limited
  5   environment not found

```
bcdock env get <name|shortId> [flags]
```

### Examples

```
  bcdock env get my-env
  bcdock env get my-env -o json
  bcdock env get a1b2c3d4
```

### Options

```
  -h, --help   help for get
```

### Options inherited from parent commands

```
      --api-url string     API base URL (env: BCDOCK_API_URL)
      --no-color           Disable colored output
  -o, --output string      Output format: table, json, csv (default "table")
  -q, --quiet              Suppress non-essential output
      --timeout duration   Request timeout (default 30s)
      --token string       API token (env: BCDOCK_TOKEN)
```

### SEE ALSO

* [bcdock env](bcdock_env.md)	 - Manage Business Central environments

