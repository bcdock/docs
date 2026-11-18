---
title: bcdock config
---

## bcdock config

Discover available regions and configurations

### Synopsis

Discover what Azure regions and BC configurations the BCDock platform supports.

For BC version and country discovery, prefer 'bcdock artifacts list' which
also shows pre-built image availability (FAST column).

Exit codes:
  0   ok
  1   general error

### Examples

```
  bcdock config regions
  bcdock config regions -o json
```

### Options

```
  -h, --help   help for config
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
* [bcdock config list](bcdock_config_list.md)	 - List all available configurations (versions, countries, regions)
* [bcdock config regions](bcdock_config_regions.md)	 - List available Azure regions
* [bcdock config versions](bcdock_config_versions.md)	 - List available BC versions (use 'bcdock artifacts list' instead)

