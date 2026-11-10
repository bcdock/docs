---
title: bcdock companies set-location
---

## bcdock companies set-location

Set the active company's default country and region for new environments

### Synopsis

Set the active company's default location: a country, and optionally the Azure
region within it. New environments default to it; existing environments do not move.

Without --region the country's default region is used. --region must be one of the
country's regions (see 'bcdock config regions'). Owners and admins only.

Auth: any API key scope; your role in the company must be owner or admin.

Exit codes:
  0   ok
  1   general error (unknown country code, or a region outside that country)
  3   auth failure (missing or invalid token, or not an owner/admin)
  4   rate-limited
  5   company not found

```
bcdock companies set-location <country-code> [flags]
```

### Examples

```
  bcdock companies set-location AU
  bcdock companies set-location US --region centralus
  bcdock companies set-location AU -o json
```

### Options

```
  -h, --help            help for set-location
      --region string   Azure region within the country (default: the country's default region)
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

* [bcdock companies](bcdock_companies.md)	 - Manage companies (billing entities)

