---
title: bcdock env delete
---

## bcdock env delete

Delete an environment

### Synopsis

Delete an environment and free its pool slot. Prompts for confirmation
unless --force is passed.

Use --wait to block until the deletion is fully complete. With --wait, the
command polls until the status is 'deleted'; without --wait, deletion is
started asynchronously.

Exit codes:
  0   ok
  3   auth failure (missing or invalid token)
  4   rate-limited
  5   environment not found

```
bcdock env delete <name|shortId> [flags]
```

### Examples

```
  bcdock env delete my-env
  bcdock env delete my-env --force
  bcdock env delete my-env --force --wait
```

### Options

```
      --force                   Skip confirmation prompt
  -h, --help                    help for delete
      --wait                    Block until fully cleaned up
      --wait-timeout duration   Max time to wait (default: 5m)
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

