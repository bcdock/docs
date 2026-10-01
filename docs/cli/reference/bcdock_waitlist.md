---
title: bcdock waitlist
---

## bcdock waitlist

Join the BCDock waitlist

### Synopsis

Join the BCDock waitlist.

BCDock is in early access. Submit a waitlist entry and an admin reviews it, then
emails you an invite code (typically within 48 hours). Once you have the code,
run 'bcdock auth signup'.

Exit codes:
  0   ok
  1   general error
  4   rate-limited

### Examples

```
  bcdock waitlist join --name "Jane Smith" --email jane@example.com
```

### Options

```
  -h, --help   help for waitlist
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
* [bcdock waitlist join](bcdock_waitlist_join.md)	 - Submit a waitlist entry non-interactively (CI-friendly)

