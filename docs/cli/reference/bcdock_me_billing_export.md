---
title: bcdock me billing export
---

## bcdock me billing export

Download per-environment usage and cost as CSV

### Synopsis

Download the active company's usage per environment as CSV: one row per
environment with its hours and cost for the period. The same file as the portal's
billing export. It streams to stdout, or to --out.

--from and --to are dates (YYYY-MM-DD); they default to the last 30 days.

Auth: an API key with env:read or billing:write; you must be a member of the company.

Exit codes:
  0   ok
  1   general error (a date not in YYYY-MM-DD, or a write failure)
  3   auth failure (missing or invalid token, or a key without env:read/billing:write)
  4   rate-limited
  5   company not found

```
bcdock me billing export [flags]
```

### Examples

```
  bcdock me billing export > usage.csv
  bcdock me billing export --from 2026-09-01 --to 2026-09-30 --out september.csv
```

### Options

```
      --from string   First day, YYYY-MM-DD (default: 30 days ago)
  -h, --help          help for export
      --out string    Write the CSV to this file instead of stdout
      --to string     Last day, YYYY-MM-DD (default: today)
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

* [bcdock me billing](bcdock_me_billing.md)	 - View your subscription, payment method, and invoice history

