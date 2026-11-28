---
title: bcdock me delete
---

## bcdock me delete

Schedule account deletion in 30 days (reversible until then)

### Synopsis

Schedule anonymisation of your account in 30 days. Within that window:
  - your running envs are hibernated to stop active-rate billing
  - companies you sole-own are flagged for anonymisation
  - companies you co-own transfer ownership to the oldest co-member
  - you can sign back in any time to cancel ('me cancel-deletion' or just re-signin)

Confirm by passing --confirm with your account email. The CLI never deletes
based on prompts; --confirm is mandatory for unattended / agent use.

Exit codes:
  0   ok
  1   general error (wrong --confirm email)
  3   auth failure (missing or invalid token)

```
bcdock me delete [flags]
```

### Examples

```
  bcdock me delete --confirm you@example.com
  bcdock me delete --confirm you@example.com -o json
```

### Options

```
      --confirm string   Must equal your account email (required)
  -h, --help             help for delete
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

