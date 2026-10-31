---
title: bcdock companies list
---

## bcdock companies list

List companies you are a member of

### Synopsis

List all companies your account belongs to and your role in each.

A company is the billing entity in BCDock - environments, invoices, and usage
roll up to a company. Use 'bcdock companies switch' to change the active company.

Exit codes:
  0   ok
  3   auth failure (missing or invalid token)
  4   rate-limited

```
bcdock companies list [flags]
```

### Examples

```
  bcdock companies list
  bcdock companies list -o json
```

### Options

```
  -h, --help   help for list
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

