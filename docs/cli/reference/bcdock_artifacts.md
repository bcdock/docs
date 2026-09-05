---
title: bcdock artifacts
---

## bcdock artifacts

Discover BC artifact versions and countries

### Synopsis

Browse the BC artifact catalog for available versions.

Use this before 'env create' to find valid version and country combinations.
FAST=yes means a pre-built image is ready (~7-15 min on a warm pool vs ~78 min
first-time image build).

Exit codes:
  0   ok
  1   general error

### Examples

```
  bcdock artifacts list --region australiaeast --fast-only
  bcdock artifacts list --region australiaeast --country au
  bcdock artifacts countries
```

### Options

```
  -h, --help   help for artifacts
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

* [bcdock](bcdock.md)	 - BCDock CLI - manage Business Central environments
* [bcdock artifacts countries](bcdock_artifacts_countries.md)	 - List countries with active BC artifact versions
* [bcdock artifacts list](bcdock_artifacts_list.md)	 - List BC versions available in a region

