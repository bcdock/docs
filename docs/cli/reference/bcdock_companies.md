---
title: bcdock companies
---

## bcdock companies

Manage companies (billing entities)

### Synopsis

List and switch between companies.

A company is the billing entity in BCDock. Use 'companies switch' to change
which company's environments and billing context are active.

Exit codes:
  0   ok
  1   general error

### Examples

```
  bcdock companies list
  bcdock companies switch contoso
  bcdock companies switch 3072f5a0-0000-0000-0000-000000000000
```

### Options

```
  -h, --help   help for companies
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
* [bcdock companies list](bcdock_companies_list.md)	 - List companies you are a member of
* [bcdock companies switch](bcdock_companies_switch.md)	 - Switch active company context

