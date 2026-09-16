---
title: URL shape
description: Every BCDock environment gets its own HTTPS URL under bcdock.io - stable across hibernation, wildcard-TLS by default, drop-in compatible with VS Code AL launch.json.
---

# URL shape

Every BCDock environment is reachable at a unique HTTPS URL under `bcdock.io`:

```
https://my-test-env-a1b2c3d4.bcdock.io/BC/
       ^^^^^^^^^^^^^^^^^^^^^                
       env name + short ID                  
                                ^^^^^^^^^^^ 
                                base zone   
```

- **Env name** - DNS-safe, 3-40 characters. You pick it at create time.
- **Short ID** - 8 hex characters appended automatically so two envs with the same name can coexist.
- **Base zone** - `bcdock.io` for production.

The URL is **stable**. It survives hibernation, resume, and is preserved when we move the env's compute between pools (different region, autoscaler-rebalanced, etc.). Bookmarks, AL `launch.json` configs, and saved BC clients keep working.

## BC endpoints

Each environment exposes the standard BC HTTP surfaces at well-known paths under the env URL:

| Path | Purpose |
|---|---|
| `/BC/` | Web client (default browser landing) |
| `/BC-dev/` | Dev endpoint - `bcdock env publish` posts to `/BC-dev/dev/apps` |
| `/BC-soap/` | SOAP endpoint - Web Service Access Key auth |
| `/BC-rest/` | OData / REST endpoint - Web Service Access Key auth |

The symmetric `BC-{purpose}` naming means every BC interface lives under the same hostname, distinguished only by path.

## Use with VS Code `launch.json`

VS Code's AL extension reads `.vscode/launch.json` to know which BC server to publish to. Let the CLI emit it — the field values (especially `server` and `serverInstance`) are derived from the env's actual dev endpoint, so hand-editing them is fragile:

```bash
bcdock env launch-json my-test-env --out .vscode/launch.json
```

The emitted block looks like this (values derived from `bcdock env get`):

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "BCDock: my-test-env",
      "type": "al",
      "request": "launch",
      "environmentType": "OnPrem",
      "server": "https://my-test-env-a1b2c3d4.bcdock.io",
      "serverInstance": "BC-dev",
      "authentication": "UserPassword",
      "tenant": "default",
      "schemaUpdateMode": "Synchronize"
    }
  ]
}
```

| `launch.json` field | Where it comes from |
|---|---|
| `server` | Origin of `devEndpointUrl` from `bcdock env get`. |
| `serverInstance` | First path segment of `devEndpointUrl` - `BC-dev` on modern envs. |
| `authentication` | `UserPassword`. |
| `tenant` | `default` (BCDock envs ship with a single default tenant). |
| `schemaUpdateMode` | `Synchronize` for compatible changes; `ForceSync` if you've changed table fields. |

Credentials for the `UserPassword` flow are the BC `Administrator` user and the password from `bcdock env credentials <name>` (a plain `bcdock env get` gives you the username, not the password). VS Code will prompt the first time and cache in the OS credential store - `bcdock env launch-json` deliberately does not write credentials into the file.

For the CLI-driven AL loop (no VS Code), `bcdock al compile` and `bcdock env publish` use the dev endpoint directly - no `launch.json` needed. See [AL extension loop](../guides/al-extension-loop.md).

## Why this shape matters

1. **URLs are stable.** An env keeps its URL across hibernation, resume, even cross-region moves. Bookmarks and `launch.json` configurations keep working as the platform moves the env's compute behind the scenes.
2. **HTTPS is automatic.** Every env is reachable over HTTPS on first create. TLS is platform-managed; customers don't need to provision or rotate certificates.
3. **Direct HTTP to BC.** `bcdock env publish` POSTs straight to `https://<env>.bcdock.io/BC-dev/dev/apps` over HTTPS - no PowerShell wrapper, no platform proxy in the data path. The same URL works from VS Code, scripts, and agents.

## Read more

- [Reference -> API keys](../reference/api-keys.md) - auth for these URLs
- [Guides -> AL extension loop](../guides/al-extension-loop.md) - concrete example of using the dev endpoint
