---
title: bcdock auth set-token
---

## bcdock auth set-token

Store an API token persistently

### Synopsis

Store an API key in ~/.bcdock/credentials.json for all future commands.

Generate API keys at: https://app.bcdock.io/profile/api-keys

The token is used in order of precedence:
  1. --token flag
  2. BCDOCK_TOKEN environment variable  (env: BCDOCK_TOKEN)
  3. ~/.bcdock/credentials.json (set by this command)

Exit codes:
  0   ok
  1   general error (cannot write credentials file)

```
bcdock auth set-token <token> [flags]
```

### Examples

```
  bcdock auth set-token bdk_xxxxxxxxxxxxxxxxxxxx
```

### Options

```
  -h, --help   help for set-token
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

