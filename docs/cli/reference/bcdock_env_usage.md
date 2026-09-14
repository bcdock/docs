---
title: bcdock env usage
---

## bcdock env usage

Show billing usage for an environment

### Synopsis

Show the billing usage timeline for one environment: total running hours,
total billed amount, and the per-day segment breakdown.

For company-wide usage across all environments, use 'bcdock usage'.

Exit codes:
  0   ok
  3   auth failure (missing or invalid token)
  4   rate-limited
  5   environment not found

```
bcdock env usage <name|shortId> [flags]
```

### Examples

```
  bcdock env usage my-env
  bcdock env usage my-env -o json
```

### Options

```
  -h, --help   help for usage
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

