---
title: bcdock env open
---

## bcdock env open

Open the BC Web Client in a browser

### Synopsis

Open the BC Web Client URL for the given environment in the default browser.
This command is not yet implemented.

To get the URL today:
  bcdock env get my-env -o json | jq -r .webClientUrl

Exit codes:
  1   general error (not yet implemented)

```
bcdock env open <name|shortId> [flags]
```

### Examples

```
  bcdock env open my-env
```

### Options

```
  -h, --help   help for open
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

