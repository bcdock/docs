---
title: bcdock env logs
---

## bcdock env logs

Show container logs (default) or provisioning log history

### Synopsis

Fetch logs for a BC environment.

Default: last N container log lines (stdout/stderr from the BC process).
--provisioning: provisioning log history from Loki (queued/creating/failed
  stage messages, useful for diagnosing why an env failed to start).
--follow: stream live container logs via SSE until ctrl+c.

--tail controls line count for non-follow modes (default: 100).

Exit codes:
  0   ok
  3   auth failure (missing or invalid token)
  5   environment not found

```
bcdock env logs <name|shortId> [flags]
```

### Examples

```
  bcdock env logs my-env
  bcdock env logs my-env --tail 200
  bcdock env logs my-env --provisioning
  bcdock env logs my-env --follow
```

### Options

```
      --follow         Stream logs in real-time
  -h, --help           help for logs
      --provisioning   Show provisioning logs
      --tail int       Number of lines to show (default 100)
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

