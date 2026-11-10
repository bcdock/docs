---
title: bcdock auth whoami
---

## bcdock auth whoami

Show the currently authenticated user

### Synopsis

Print the email, display name, role, and company for the authenticated user.

Useful as a quick auth check in scripts and agent flows. Returns a non-zero
exit code if the token is missing or invalid.

Exit codes:
  0   ok
  1   general error (not authenticated)
  3   auth failure (invalid token)
  4   rate-limited

```
bcdock auth whoami [flags]
```

### Examples

```
  bcdock auth whoami
  bcdock auth whoami -o json
```

### Options

```
  -h, --help   help for whoami
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

