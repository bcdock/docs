---
title: bcdock config versions
---

## bcdock config versions

List available BC versions (use 'bcdock artifacts list' instead)

### Synopsis

List available BC versions. This command is not yet implemented - use
'bcdock artifacts list' to browse versions with pre-built image information.

Exit codes:
  1   general error (not yet implemented)

```
bcdock config versions [flags]
```

### Examples

```
  bcdock artifacts list --region australiaeast --fast-only
```

### Options

```
      --country string   Filter by country
      --fast-only        Only versions with pre-built images
  -h, --help             help for versions
      --region string    Filter by region
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

* [bcdock config](bcdock_config.md)	 - Discover available regions and configurations

