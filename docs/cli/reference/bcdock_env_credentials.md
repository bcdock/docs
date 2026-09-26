---
title: bcdock env credentials
---

## bcdock env credentials

Reveal an environment's BC admin credentials

### Synopsis

Reveal the BC admin password and web-service access key for an environment.

These are no longer returned by 'bcdock env get'. A plain read of an environment used to
carry its live credentials in the response - into every log of that response, every proxy
in front of it, and every browser tab polling it. They now come only from here, on an
explicit request, and every reveal is recorded in the audit trail.

The username is not a secret and stays on 'bcdock env get'.

  bcdock env credentials my-env
  bcdock env credentials my-env -o json

The value is printed to stdout. It is never accepted as a flag or an argument anywhere in
this CLI, so it does not reach your shell history or the process list.

Output formats:
  -o table  (default) vertical key/value layout, one field per line
  -o json   the reveal record (use for scripting)

Exit codes:
  0   ok
  3   auth failure (missing or invalid token)
  4   rate-limited
  5   environment not found

```
bcdock env credentials <env> [flags]
```

### Examples

```
  bcdock env credentials my-env
  bcdock env credentials my-env -o json
  bcdock env credentials a1b2c3d4
```

### Options

```
  -h, --help   help for credentials
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

