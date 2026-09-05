---
title: bcdock env list
---

## bcdock env list

List environments

### Synopsis

List all environments for the active company. Excludes deleted environments.

Use --status to filter by environment state (running, creating, hibernated,
failed, etc.). Use --version to filter by BC version. Use --region to filter
by Azure region.

Exit codes:
  0   ok
  3   auth failure (missing or invalid token)
  4   rate-limited

```
bcdock env list [flags]
```

### Examples

```
  bcdock env list
  bcdock env list -o json
  bcdock env list --status running
  bcdock env list --version 25.5 --region australiaeast
```

### Options

```
  -h, --help             help for list
      --region string    Filter by region
      --status string    Filter by status
      --version string   Filter by BC version
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

