---
title: bcdock artifacts request
---

## bcdock artifacts request

Request a BC version that has no ready image yet

### Synopsis

Ask BCDock to build a BC version that has no pre-built image, so that
environments can be created on it. This is the same request as the portal's
"Request this version" button.

Use the full version (versionFull from 'bcdock artifacts list'). When
'bcdock env create' refuses a version because it has no ready image, its error
prints this command with the version filled in.

What happens next: BCDock replies by email, usually within the time this
command prints. Once the image is built, 'bcdock artifacts list --fast-only'
shows the version and 'bcdock env create' accepts it.

Needs the env:write scope (keys from 'bcdock auth login' have it).

Exit codes:
  0   ok, request submitted
  1   general error (for example, the version is not in the catalog for that
      country and type, or version requests are not open on this platform)
  3   auth failure (missing or invalid token)
  4   rate-limited

```
bcdock artifacts request <version> [flags]
```

### Examples

```
  bcdock artifacts list --region australiaeast --country au   # find the versionFull
  bcdock artifacts request <version> --country au
  bcdock artifacts request <version> --country us --type onprem --message "Needed for a client demo"
  bcdock artifacts request <version> --country au -o json
```

### Options

```
      --country string   Country localisation (required, e.g. au, us, gb)
  -h, --help             help for request
      --message string   Optional note for the BCDock team (up to 2000 characters)
      --multi-tenant     Multi-tenant (the default for 'env create') (default true)
      --type string      Artifact type: sandbox or onprem (default "sandbox")
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

