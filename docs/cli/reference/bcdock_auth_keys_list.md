---
title: bcdock auth keys list
---

## bcdock auth keys list

List your company's API keys (never the secrets)

### Synopsis

List the active company's API keys: id, name, the key's prefix, scopes, and
when it was created, last used and expires. The secret is never shown; it is
displayed once, when the key is created.

Exit codes:
  0   ok
  3   auth failure (missing or invalid token)
  4   rate-limited

```
bcdock auth keys list [flags]
```

### Examples

```
  bcdock auth keys list
  bcdock auth keys list -o json
```

### Options

```
  -h, --help   help for list
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

