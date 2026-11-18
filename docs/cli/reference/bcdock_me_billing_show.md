---
title: bcdock me billing show
---

## bcdock me billing show

Show current plan, subscription state, and last 12 invoices

### Synopsis

Print a snapshot of your billing state: active plan (tier, rates, env cap),
Stripe subscription status, last 12 invoices, and attached payment method.

For ongoing card / plan management use 'bcdock me billing portal' to open the
Stripe Customer Portal in a browser.

Exit codes:
  0   ok
  1   general error
  3   auth failure (missing or invalid token)
  4   rate-limited

```
bcdock me billing show [flags]
```

### Examples

```
  bcdock me billing show
  bcdock me billing show -o json
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

* [bcdock me billing](bcdock_me_billing.md)	 - View your subscription, payment method, and invoice history

