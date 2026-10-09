---
title: bcdock auth keys
---

## bcdock auth keys

List and revoke your company's API keys

### Synopsis

List and revoke the API keys of your active company.

Keys are created in the portal (Profile -> API keys), or by 'bcdock auth login'.
A key cannot create keys, but any key of the company can list and revoke them,
so a leaked key can be revoked from the CLI.

Exit codes:
  0   ok
  1   general error

### Examples

```
  bcdock auth keys list
  bcdock auth keys revoke <id>
```

### Options

```
  -h, --help   help for keys
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
* [bcdock auth keys list](bcdock_auth_keys_list.md)	 - List your company's API keys (never the secrets)
* [bcdock auth keys revoke](bcdock_auth_keys_revoke.md)	 - Revoke one of your company's API keys

