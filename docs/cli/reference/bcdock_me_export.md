---
title: bcdock me export
---

## bcdock me export

Request a ZIP of all data we hold for your account and company

### Synopsis

Request a GDPR-style data export. The platform builds a ZIP of CSVs
covering your environments, usage history, audit log, billing history, email
log, etc., uploads it to encrypted blob storage, and emails you a 24-hour
SAS download link.

Idempotent: if a request is already pending or processing, the existing one is
returned instead of creating a duplicate.

Exit codes:
  0   ok
  1   general error
  3   auth failure (missing or invalid token)
  4   rate-limited
  124 timeout (--wait only: export not ready within --wait-timeout)

```
bcdock me export [flags]
```

### Examples

```
  bcdock me export
  bcdock me export --wait
  bcdock me export --wait --out export.zip
  bcdock me export -o json
```

### Options

```
  -h, --help                    help for export
      --out string              When --wait succeeds, download the ZIP to this path
      --wait                    Poll until status flips to ready/failed/expired
      --wait-timeout duration   Maximum time to poll when --wait is set (exit 124 if exceeded) (default 5m0s)
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

* [bcdock me](bcdock_me.md)	 - Manage your own account (export data, request deletion, cancel)

