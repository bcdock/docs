---
title: bcdock artifacts list
---

## bcdock artifacts list

List BC versions available in a region

### Synopsis

List BC artifact versions available in the given Azure region.

FAST=yes rows have a pre-built VM image, which means provisioning takes 7-15
minutes on a warm pool instead of ~78 minutes for an image build. Always prefer
fast configs unless you explicitly need a specific version.

Use --country to narrow to one localisation. Use --type to filter to Sandbox
or OnPrem artifacts. Use --fast-only to show only rows with a pre-built image.

Exit codes:
  0   ok
  1   general error (e.g. invalid --type value)
  3   auth failure (missing or invalid token)
  4   rate-limited

```
bcdock artifacts list [flags]
```

### Examples

```
  bcdock artifacts list --region australiaeast
  bcdock artifacts list --region australiaeast --fast-only
  bcdock artifacts list --region australiaeast --country au --type sandbox
  bcdock artifacts list --region westus2 --fast-only -o json
```

### Options

```
      --country string    Filter by country code (e.g. au)
      --fast-only         Only versions with pre-built images (~7-15 min on a warm pool)
  -h, --help              help for list
      --include-preview   Include insider/preview builds
      --region string     Azure region (required, e.g. australiaeast)
      --type string       Filter by artifact type: sandbox or onprem
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

