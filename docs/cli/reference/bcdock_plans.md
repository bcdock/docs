---
title: bcdock plans
---

## bcdock plans

Browse the subscription plans

### Synopsis

Browse the plans a company can subscribe to. Switching plan is not a CLI command
yet: it opens when subscriptions do; until then it is done with BCDock.

Exit codes:
  0   ok
  1   general error

### Examples

```
  bcdock plans list
```

### Options

```
  -h, --help   help for plans
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
* [bcdock plans list](bcdock_plans_list.md)	 - List the subscription plans and their active rates

