---
title: bcdock me billing cycle
---

## bcdock me billing cycle

Show the active company's usage and cost totals for a period, and trial progress

### Synopsis

Show the active company's totals for a period: active and hibernated hours, the
cost, the plan, and how much of the plan's included time is used (the trial). The
same figures as the portal's usage page. Per-environment rows: 'bcdock usage
--by-environment'; your plan, subscription and invoices: 'bcdock me billing show'.

--from and --to are dates (YYYY-MM-DD); they default to the last 30 days.

Auth: an API key with env:read or billing:write; you must be a member of the company.

Exit codes:
  0   ok
  1   general error (a date not in YYYY-MM-DD)
  3   auth failure (missing or invalid token, or a key without env:read/billing:write)
  4   rate-limited
  5   company not found

```
bcdock me billing cycle [flags]
```

### Examples

```
  bcdock me billing cycle
  bcdock me billing cycle --from 2026-09-01 --to 2026-09-30
  bcdock me billing cycle -o json
```

### Options

```
      --from string   First day, YYYY-MM-DD (default: 30 days ago)
  -h, --help          help for cycle
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

