---
title: bcdock auth keys revoke
---

## bcdock auth keys revoke

Revoke one of your company's API keys

### Synopsis

Revoke an API key by its id (from 'bcdock auth keys list'). The key stops
working immediately for new requests. Revoking cannot be undone.

Prompts for confirmation unless --yes is passed. When stdin is not a terminal
(scripts, agents), --yes is required.

Exit codes:
  0   ok, or cancelled at the prompt
  1   general error (for example, no --yes without a terminal)
  3   auth failure (missing or invalid token)
  4   rate-limited
  5   no key with that id in your active company

```
bcdock auth keys revoke <id> [flags]
```

### Examples

```
  bcdock auth keys list
  bcdock auth keys revoke <id>
  bcdock auth keys revoke <id> --yes -o json
```

### Options

```
  -h, --help   help for revoke
      --yes    Revoke without a confirmation prompt
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

* [bcdock auth keys](bcdock_auth_keys.md)	 - List and revoke your company's API keys

