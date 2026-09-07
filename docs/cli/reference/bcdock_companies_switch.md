---
title: bcdock companies switch
---

## bcdock companies switch

Switch active company context

### Synopsis

Switch to a different company. All subsequent commands run against the new company.

New tokens are stored in ~/.bcdock/credentials.json. Pass the company name,
slug, or GUID - the CLI resolves all three.

Exit codes:
  0   ok
  3   auth failure (missing or invalid token)
  4   rate-limited
  5   company not found

```
bcdock companies switch <id|name|slug> [flags]
```

### Examples

```
  bcdock companies switch contoso
  bcdock companies switch 3072f5a0-0000-0000-0000-000000000000
```

### Options

```
  -h, --help   help for switch
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

