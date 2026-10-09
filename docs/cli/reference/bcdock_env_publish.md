---
title: bcdock env publish
---

## bcdock env publish

Publish (deploy) an AL .app to a BC environment

### Synopsis

Upload a compiled .app file to the BC dev service endpoint and run install
or upgrade codeunits server-side. Equivalent to VS Code's "AL: Publish without
debugging" - same wire protocol, no IDE required.

Wire protocol (full spec in the al-cli skill):
  POST {devEndpointUrl}apps?SchemaUpdateMode=…[&tenant=…][&DependencyPublishingOption=…]
  Authorization: Basic base64(user:password)   # from env credentials
  Content-Type: multipart/form-data; one file part = .app bytes

Schema update modes:
  synchronize  (default) - additive schema changes; preserves data
  forcesync              - recreate columns when types changed; data loss possible
  recreate               - drop and recreate tables; ALL data lost - use with care

The call is synchronous: returns only after install/upgrade codeunits finish.
Set --timeout high for large apps (default 10m).

Exit codes:
  0   ok
  1   general error (publish failed, env not running, no dev endpoint)
  3   auth failure (missing or invalid token)
  5   environment not found

```
bcdock env publish <env> <app-path> [flags]
```

### Examples

```
  bcdock env publish my-env build/MyApp_1.0.0.0.app
  bcdock env publish my-env app.app --schema-update-mode forcesync
  bcdock env publish my-env app.app --tenant default --timeout 20m
```

### Options

```
      --dependency-publishing string   Dependency handling: Default | Ignore | Strict (omitted = server default)
  -h, --help                           help for publish
      --insecure                       Skip TLS verification for the dev endpoint (use for self-signed local certs only)
      --schema-update-mode string      Schema update mode: synchronize | forcesync | recreate (recreate drops data) (default "synchronize")
      --tenant string                  BC tenant to publish into (default "default")
      --timeout duration               Max time to wait for the publish call (install/upgrade codeunits run synchronously) (default 10m0s)
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

