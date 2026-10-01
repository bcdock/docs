---
title: bcdock artifacts countries
---

## bcdock artifacts countries

List countries with active BC artifact versions

### Synopsis

List all BC localisation country codes that have at least one active artifact
version in the BCDock catalog.

Use the CODE column as the --country value for 'artifacts list' and 'env create'.

Exit codes:
  0   ok
  3   auth failure (missing or invalid token)
  4   rate-limited

```
bcdock artifacts countries [flags]
```

### Examples

```
  bcdock artifacts countries
  bcdock artifacts countries -o json
```

### Options

```
  -h, --help   help for countries
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

* [bcdock artifacts](bcdock_artifacts.md)	 - Discover BC artifact versions and countries

