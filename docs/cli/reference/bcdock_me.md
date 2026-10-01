---
title: bcdock me
---

## bcdock me

Manage your own account (export data, request deletion, cancel)

### Synopsis

User-self surface for GDPR Art. 15 / 17 and APP 12 / 13.

  bcdock me show              → identity + status + deletion schedule (if any)
  bcdock me export            → request a ZIP of all data we hold for you
  bcdock me delete            → schedule account deletion in 30 days
  bcdock me cancel-deletion   → reverse a pending deletion

Auth: requires a JWT or API key bound to your account.

Exit codes:
  0   ok
  1   general error

### Examples

```
  bcdock me show
  bcdock me export --wait
  bcdock me delete --confirm you@example.com
```

### Options

```
  -h, --help   help for me
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
* [bcdock me billing](bcdock_me_billing.md)	 - View your subscription, payment method, and invoice history
* [bcdock me cancel-deletion](bcdock_me_cancel-deletion.md)	 - Cancel a pending deletion (idempotent - no-op if nothing pending)
* [bcdock me delete](bcdock_me_delete.md)	 - Schedule account deletion in 30 days (reversible until then)
* [bcdock me export](bcdock_me_export.md)	 - Request a ZIP of all data we hold for your account and company
* [bcdock me show](bcdock_me_show.md)	 - Show your account profile (id, email, role, company, deletion status)

