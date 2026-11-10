---
title: bcdock me export latest
---

## bcdock me export latest

Show your most recent data export, and download it if it is ready

### Synopsis

Show your most recent data export in any state (pending, ready, failed or
expired), with its download link when ready. With --out, download it, without
starting a new export the way 'bcdock me export' does.

Auth: any API key scope; it reads only your own export.

Exit codes:
  0   ok (including "no export yet")
  1   general error (--out on an export that is not ready)
  3   auth failure (missing or invalid token)
  4   rate-limited

```
bcdock me export latest [flags]
```

### Examples

```
  bcdock me export latest
  bcdock me export latest --out export.zip
  bcdock me export latest -o json
```

### Options

```
  -h, --help         help for latest
      --out string   Download the latest export to this path (it must be ready)
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

* [bcdock me export](bcdock_me_export.md)	 - Request a ZIP of all data we hold for your account and company

