---
title: bcdock me show
---

## bcdock me show

Show your account profile (id, email, role, company, deletion status)

### Synopsis

Print the full profile for the authenticated user: id, email, display name,
platform role, active company, region, time zone, account status, and deletion
schedule (if a deletion request is pending).

Exit codes:
  0   ok
  1   general error (not authenticated)
  3   auth failure (invalid token)
  4   rate-limited

```
bcdock me show [flags]
```

### Examples

```
  bcdock me show
  bcdock me show -o json
```

### Options

```
  -h, --help   help for show
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

