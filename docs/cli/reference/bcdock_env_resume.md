---
title: bcdock env resume
---

## bcdock env resume

Resume a hibernated environment

### Synopsis

Restore a hibernated environment from blob storage. The environment
transitions from 'hibernated' back to 'running'.

Use --version to upgrade the BC platform version during resume (optional - the
version must be compatible with the saved state). Use --wait to block until
running or failed instead of returning immediately.

Exit codes:
  0   ok
  3   auth failure (missing or invalid token)
  4   rate-limited
  5   environment not found
  10  resume failed (provisioning error)

```
bcdock env resume <name|shortId> [flags]
```

### Examples

```
  bcdock env resume my-env
  bcdock env resume my-env --wait
  bcdock env resume my-env --version 25.5 --wait
```

### Options

```
  -h, --help                    help for resume
      --version string          Confirm upgrade to this BC version (required when upgrading)
      --wait                    Block until running or failed
      --wait-timeout duration   Max time to wait (default: 30m)
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

* [bcdock env](bcdock_env.md)	 - Manage Business Central environments

