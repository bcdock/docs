---
title: bcdock env wait
---

## bcdock env wait

Block until an environment reaches one of the requested states

### Synopsis

Wait for an environment to reach a desired status, polling every 3 seconds.

Multiple --status values are OR-ed: the command exits 0 as soon as the env
reaches any one of them.

Exit codes:
  0   one of --status values reached
  1   the environment failed (status error or failed-debug) and you did not
      wait for that status; its error message is printed
  5   environment not found
  124 no requested state reached: --timeout elapsed, or the environment
      settled in another terminal status you did not ask for (e.g. hibernated);
      its error message is printed when it has one

```
bcdock env wait <name|shortId> [flags]
```

### Examples

```
  bcdock env wait my-env --status running --timeout 30m
  bcdock env wait my-env --status hibernated --status suspended --timeout 15m
```

### Options

```
  -h, --help                 help for wait
      --status stringArray   Status to wait for (repeatable: running, error, hibernated, deleted, ...)
      --timeout duration     Max time to wait (default 30m0s)
```

### Options inherited from parent commands

```
      --api-url string   API base URL (env: BCDOCK_API_URL)
      --no-color         Disable colored output
  -o, --output string    Output format: table, json, csv (default "table")
  -q, --quiet            Suppress non-essential output
      --token string     API token (env: BCDOCK_TOKEN)
```

### SEE ALSO

* [bcdock env](bcdock_env.md)	 - Manage Business Central environments

