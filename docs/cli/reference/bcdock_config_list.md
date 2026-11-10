---
title: bcdock config list
---

## bcdock config list

List all available configurations (versions, countries, regions)

### Synopsis

List all available BC configurations - versions, countries, and regions -
in one call. This command is not yet implemented.

Use these commands today:
  bcdock config regions              - Azure regions
  bcdock artifacts list --region <r> - BC versions + countries in a region
  bcdock artifacts countries         - country codes

Exit codes:
  1   general error (not yet implemented)

```
bcdock config list [flags]
```

### Examples

```
  bcdock config regions
  bcdock artifacts list --region australiaeast --fast-only
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

* [bcdock config](bcdock_config.md)	 - Discover available regions and configurations

