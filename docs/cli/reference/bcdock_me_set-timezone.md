---
title: bcdock me set-timezone
---

## bcdock me set-timezone

Set the time zone the portal shows your times in

### Synopsis

Set your display time zone, an IANA id such as Australia/Melbourne or
America/Chicago (UTC for UTC). The portal shows times in it; the API keeps
storing UTC. The id is checked before it is sent, so a typo fails here.

Auth: any API key scope; it changes only your own preference.

Exit codes:
  0   ok
  1   general error (not an IANA time zone id)
  3   auth failure (missing or invalid token)
  4   rate-limited

```
bcdock me set-timezone <iana-timezone> [flags]
```

### Examples

```
  bcdock me set-timezone Australia/Melbourne
  bcdock me set-timezone UTC
```

### Options

```
  -h, --help   help for set-timezone
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

