---
title: bcdock me billing portal
---

## bcdock me billing portal

Print the Stripe Customer Portal URL for managing card / plan / invoices

### Synopsis

Creates a short-lived Stripe Customer Portal session and returns the URL.
Open it in a browser to update payment method, change plan, or cancel.

Returns 400 if your account has no Stripe Customer yet (still on free trial -
use 'bcdock me billing checkout' to add a card and pick a tier first).

Exit codes:
  0   ok
  1   general error (no Stripe customer yet)
  3   auth failure (missing or invalid token)
  4   rate-limited

```
bcdock me billing portal [flags]
```

### Examples

```
  bcdock me billing portal
  bcdock me billing portal -o json
```

### Options

```
  -h, --help                help for portal
      --return-url string   URL Stripe redirects back to after the user closes the portal
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

