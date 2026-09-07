---
title: bcdock env download-symbols
---

## bcdock env download-symbols

Download AL symbol packages from a BC environment's dev endpoint

### Synopsis

Fetch the symbol packages an AL project depends on from the connected BC
environment and write them to .alpackages/. Equivalent to VS Code's
"AL: Download symbols" - same wire protocol, no IDE required.

Reads app.json (default ./app.json) for:
  - "application" version  → Microsoft_Application_*.app   (System + Base App combined)
  - "platform" version     → Microsoft_System_*.app        (platform symbols)
  - "dependencies"         → one .app per entry            (per-tenant or 3rd-party deps)

Wire protocol (per Microsoft.Dynamics.Nav.Deployment.dll):
  GET {devEndpointUrl}dev/packages?publisher=<P>&appName=<N>&versionText=<V>[&tenant=<T>]
  Authorization: Basic base64(user:password)
  Accept: application/octet-stream, */*
  → binary .app file in response body
(devEndpointUrl is {server}/{serverInstance}/ - launch.json-shaped - so we
append BC's dev-API path "dev/packages" to it.)

By default, packages already present in --out-dir are skipped (incremental).
Use --force to re-download.

Exit codes:
  0   ok
  1   general error (download failed, env not running, no dev endpoint)
  3   auth failure (missing or invalid token)
  5   environment not found

```
bcdock env download-symbols <env> [flags]
```

### Examples

```
  bcdock env download-symbols my-env
  bcdock env download-symbols my-env --app-json apps/MyExt/app.json --out-dir apps/MyExt/.alpackages
  bcdock env download-symbols my-env --force --tenant default
```

### Options

```
      --app-json string    Path to the app.json driving symbol selection (default "app.json")
      --force              Re-download even if a matching .app already exists in --out-dir
  -h, --help               help for download-symbols
      --insecure           Skip TLS verification (use for self-signed local certs only)
      --out-dir string     Directory to write downloaded .app symbol packages into (default ".alpackages")
      --tenant string      BC tenant the symbols belong to (default "default")
      --timeout duration   Per-package download timeout (default 5m0s)
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

