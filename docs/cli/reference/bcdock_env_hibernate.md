---
title: bcdock env hibernate
---

## bcdock env hibernate

Hibernate an environment (saves to blob storage, frees pool slot)

### Synopsis

Save the environment state to blob storage and free its pool VM. The
environment transitions from 'running' to 'hibernated'. While hibernated, only
the base-fee is billed (no active-rate charges).

Use 'bcdock env resume' to bring it back. Use --wait to block until hibernation
completes instead of returning immediately.

Exit codes:
  0   ok
  3   auth failure (missing or invalid token)
  4   rate-limited
  5   environment not found
  10  hibernation failed

```
bcdock env hibernate <name|shortId> [flags]
```

### Examples

```
  bcdock env hibernate my-env
  bcdock env hibernate my-env --wait
```

### Options

```
  -h, --help                    help for hibernate
      --wait                    Block until hibernated or failed
      --wait-timeout duration   Max time to wait (default: 10m)
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

