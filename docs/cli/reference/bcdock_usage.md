---
title: bcdock usage
---

## bcdock usage

Show company-level usage and billing

### Synopsis

Show usage summary for the active company.

Defaults to the last 30 days. Use --from/--to for a custom date range.
Use --by-environment for a per-environment breakdown.

For usage scoped to a single environment, use 'bcdock env usage <name>'.

Exit codes:
  0   ok
  1   general error (no active company)
  3   auth failure (missing or invalid token)
  4   rate-limited

```
bcdock usage [flags]
```

### Examples

```
  bcdock usage
  bcdock usage --from 2026-03-01 --to 2026-03-31
  bcdock usage --by-environment
  bcdock usage -o csv > usage.csv
```

### Options

```
      --by-environment   Show per-environment breakdown
      --from string      Start date (YYYY-MM-DD, default: 30 days ago)
  -h, --help             help for usage
      --to string        End date (YYYY-MM-DD, default: today)
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

* [bcdock](bcdock.md)	 - BCDock CLI - manage Business Central environments

