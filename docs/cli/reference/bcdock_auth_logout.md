---
title: bcdock auth logout
---

## bcdock auth logout

Clear stored credentials

### Synopsis

Invalidate the current session server-side and clear the token from
~/.bcdock/credentials.json. Safe to run even if not authenticated.

Does not revoke API keys created via the portal; use the portal API-keys page
to revoke long-lived keys.

Exit codes:
  0   ok
  1   general error (cannot clear credentials file)

```
bcdock auth logout [flags]
```

### Examples

```
  bcdock auth logout
```

### Options

```
  -h, --help   help for logout
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

* [bcdock auth](bcdock_auth.md)	 - Authenticate with the BCDock platform

