---
title: bcdock version
---

## bcdock version

Print the bcdock CLI version

### Synopsis

Print the bcdock CLI version, git commit, and API major version.

This command never checks auth or calls the API. Use it to confirm which
CLI build is installed. The CLI probes the platform for a minimum-version
requirement on each command run and warns to stderr when upgrade is needed.

Exit codes:
  0   ok

```
bcdock version [flags]
```

### Examples

```
  bcdock version
  bcdock version -o json
```

### Options

```
  -h, --help   help for version
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

