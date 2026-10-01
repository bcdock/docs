---
title: bcdock me billing
---

## bcdock me billing

View your subscription, payment method, and invoice history

### Synopsis

Subscription state, last 12 invoices, and a one-click handoff to the
Stripe-hosted Customer Portal where you manage your card and plan.

  bcdock me billing show     → mirror snapshot (plan + subscription + invoices)
  bcdock me billing portal   → URL for the Stripe Customer Portal session
  bcdock me billing checkout → start a Stripe Checkout flow to add a card

Auth: requires a JWT or API key bound to your account.

Exit codes:
  0   ok
  1   general error

### Examples

```
  bcdock me billing show
  bcdock me billing portal
  bcdock me billing checkout --tier starter --currency usd
```

### Options

```
  -h, --help   help for billing
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
* [bcdock me billing checkout](bcdock_me_billing_checkout.md)	 - Start a Stripe Checkout flow for a chosen tier+currency (prints the hosted URL)
* [bcdock me billing portal](bcdock_me_billing_portal.md)	 - Print the Stripe Customer Portal URL for managing card / plan / invoices
* [bcdock me billing show](bcdock_me_billing_show.md)	 - Show current plan, subscription state, and last 12 invoices

