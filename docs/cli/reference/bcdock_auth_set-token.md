---
title: bcdock auth set-token
---

## bcdock auth set-token

Store an API token persistently

### Synopsis

Store an API key in ~/.bcdock/credentials.json for all future commands.

The key is read from stdin, so it never lands in your shell history or the
process list: pipe it in, or run the command and paste it when asked. Passing
the key as an argument still works, with a warning, because the key is then
saved in your shell history.

Generate API keys at: https://app.bcdock.io/profile/api-keys

The token is used in order of precedence:
  1. --token flag
  2. BCDOCK_TOKEN environment variable  (env: BCDOCK_TOKEN)
  3. ~/.bcdock/credentials.json (set by this command)

Exit codes:
  0   ok
  1   general error (no key on stdin, or cannot write credentials file)

```
bcdock auth set-token [flags]
```

### Examples

```
  pbpaste | bcdock auth set-token                 # macOS clipboard
  Get-Clipboard | bcdock auth set-token           # Windows PowerShell
  bcdock auth set-token < ~/bcdock-key.txt
  bcdock auth set-token                           # then paste the key and press Enter
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

