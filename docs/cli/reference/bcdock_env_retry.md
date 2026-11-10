---
title: bcdock env retry
---

## bcdock env retry

Retry provisioning an environment that failed

### Synopsis

Retry provisioning an environment in the 'error' status, the same as the
portal's Retry button. Only a failed environment can be retried; for any other
status the API refuses and nothing changes.

Use --wait to block until the environment is running or has failed again.

Needs the env:write scope (keys from 'bcdock auth login' have it).

Exit codes:
  0   ok
  1   general error, including the environment not being in 'error', provisioning
      failing again (its error message is printed), or a --wait timeout
  3   auth failure (missing or invalid token)
  4   rate-limited
  5   environment not found

```
bcdock env retry <name|shortId> [flags]
```

### Examples

```
  bcdock env retry my-env
  bcdock env retry my-env --wait
  bcdock env retry my-env --wait -o json
```

### Options

```
  -h, --help                    help for retry
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

