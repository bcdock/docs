---
title: bcdock me cancel-deletion
---

## bcdock me cancel-deletion

Cancel a pending deletion (idempotent - no-op if nothing pending)

### Synopsis

Reverse a pending account deletion. Returns cancelled=true if there was
a pending request, cancelled=false otherwise - safe to call unconditionally.

Exit codes:
  0   ok
  3   auth failure (missing or invalid token)

```
bcdock me cancel-deletion [flags]
```

### Examples

```
  bcdock me cancel-deletion
  bcdock me cancel-deletion -o json
```

### Options

```
  -h, --help   help for cancel-deletion
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

* [bcdock me](bcdock_me.md)	 - Manage your own account (export data, request deletion, cancel)

