---
title: bcdock env launch-json
---

## bcdock env launch-json

Emit a VS Code launch.json config for publishing to a BC environment

### Synopsis

Generate the launch.json configuration block VS Code's AL extension needs
to publish (Ctrl+F5) to a BCDock environment, derived from the env's DTO.

By default emits a complete launch.json (single configuration in the array)
to stdout. With --out, writes the file (creating parent dirs).

The values are derived from 'bcdock env get':
  server         = origin of devEndpointUrl
  serverInstance = first path segment of devEndpointUrl (BC-dev / {name}-dev)
  authentication = "UserPassword"  (BCDock containers don't ship Entra auth)
  tenant         = "default"       (BCDock ships single-tenant=default for MT)

Credentials are NOT written to launch.json - VS Code prompts on first
publish and caches in the OS credential store.

Exit codes:
  0   ok
  1   general error (env not ready, no devEndpointUrl yet)
  3   auth failure (missing or invalid token)
  5   environment not found

```
bcdock env launch-json <env> [flags]
```

### Examples

```
  bcdock env launch-json my-env
  bcdock env launch-json my-env --out .vscode/launch.json
  bcdock env launch-json my-env --config-name "BC sandbox"
```

### Options

```
      --config-name string   Name field for the configuration (default: 'BCDock: <displayName>')
  -h, --help                 help for launch-json
      --launch-browser       Set launchBrowser=true (VS Code opens browser after publish; URL may not match the env's serverInstance routing)
      --out string           Write launch.json to this path instead of stdout
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

