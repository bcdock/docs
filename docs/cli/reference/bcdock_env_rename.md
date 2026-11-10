---
title: bcdock env rename
---

## bcdock env rename

Change an environment's display name

### Synopsis

Change the name an environment shows in the portal and in 'env list', the
same as the portal's Rename. Only the display name changes: the environment's
own name (its container name, used in its URLs) never changes, so its URLs and
credentials stay the same.

The display name is 1 to 60 characters.

Needs the env:write scope (keys from 'bcdock auth login' have it).

Exit codes:
  0   ok
  1   general error (for example, a name over 60 characters, or a deleted environment)
  3   auth failure (missing or invalid token)
  4   rate-limited
  5   environment not found

```
bcdock env rename <name|shortId> <display-name> [flags]
```

### Examples

```
  bcdock env rename my-env "Credit hold demo"
  bcdock env rename a1b2c3d4 "UAT - client X" -o json
```

### Options

```
  -h, --help   help for rename
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

* [bcdock env](bcdock_env.md)	 - Manage Business Central environments

