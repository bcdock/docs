---
title: bcdock me billing checkout
---

## bcdock me billing checkout

Start a Stripe Checkout flow for a chosen tier+currency (prints the hosted URL)

### Synopsis

Creates a Stripe Checkout Session and prints the URL to open in a browser.
Stripe handles card collection, 3DS, Apple/Google Pay, then redirects back to the
portal /billing page. BCDock mirrors the new subscription server-side within
seconds of the customer completing the flow.

This is the only path for trial users to add a card and convert to a paid tier.
After conversion, use 'bcdock me billing portal' for ongoing card / plan management.

Exit codes:
  0   ok
  1   general error (invalid tier or currency)
  3   auth failure (missing or invalid token)
  4   rate-limited

```
bcdock me billing checkout [flags]
```

### Examples

```
  bcdock me billing checkout --tier starter --currency aud
  bcdock me billing checkout --tier pro --currency usd
```

### Options

```
      --cancel-url string    URL Stripe redirects to if the user cancels (optional)
      --currency string      Currency: aud|usd (required)
  -h, --help                 help for checkout
      --success-url string   URL Stripe redirects to after a successful payment (optional)
      --tier string          Tier to subscribe to: payg|starter|pro|business|enterprise (required)
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

