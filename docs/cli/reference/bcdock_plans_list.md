---
title: bcdock plans list
---

## bcdock plans list

List the subscription plans and their active rates

### Synopsis

List the plans a company can subscribe to, cheapest active rate first, with each
plan's environment cap. The same catalogue as the pricing page.

Auth: any API key scope (reference data, the same for every company).

Exit codes:
  0   ok
  3   auth failure (missing or invalid token)
  4   rate-limited

```
bcdock plans list [flags]
```

### Examples

```
  bcdock plans list
  bcdock plans list -o json
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

* [bcdock plans](bcdock_plans.md)	 - Browse the subscription plans

