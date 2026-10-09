---
title: bcdock config regions
---

## bcdock config regions

List available Azure regions

### Synopsis

List the Azure regions where BCDock can provision environments.

Use the REGION column value as --region in 'env create' and 'artifacts list'.

Exit codes:
  0   ok
  3   auth failure (missing or invalid token)
  4   rate-limited

```
bcdock config regions [flags]
```

### Examples

```
  bcdock config regions
  bcdock config regions -o json
```

### Options

```
  -h, --help   help for regions
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

