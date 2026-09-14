---
title: AL extension loop — terminal-only AL development
description: Four CLI verbs replace VS Code for the AL authoring loop. Pull symbols, compile, publish, generate launch.json. No IDE required.
schema_type: HowTo
---

# AL extension loop

Goal: develop and ship a Business Central AL extension end-to-end from a terminal — no VS Code, no global `alc` install, no `curl` calls against `/dev/*`. Four CLI verbs do it: `env download-symbols`, `al compile`, `env publish`, `env launch-json`.

The wire spec is extracted from `Microsoft.Dynamics.Nav.Deployment.dll` (the `.NET` assembly that ships with every BC container). The CLI's verbs are thin wrappers over the same HTTPS endpoints the AL VS Code extension calls — `/dev/packages` for symbols, `/dev/apps` for publish, `/ALLanguage.vsix` (port 8080) for the compiler bundle. Documented under [Wire URLs](#wire-urls-informational) below for the "reverse-engineer this when bcdock breaks" path.

## Prerequisites

- A running BC environment. If you don't have one: `bcdock env create --name my-dev --version 27 --country au --wait`.
- An AL project with `app.json` declaring the symbol packages your code references.
- `bcdock` on `PATH` and authenticated (`bcdock auth whoami` returns your identity).

## The four phases

```bash
ENV=my-dev   # whichever env name you used

# 1. Pull the symbol packages your app.json declares
bcdock env download-symbols "$ENV" --out-dir .alpackages

# 2. Compile with the env's bundled alc (matched to the env's BC platform version)
bcdock al compile --env "$ENV" --out build/MyApp.app

# 3. Publish — install/upgrade codeunits run synchronously
bcdock env publish "$ENV" build/MyApp.app

# 4. Generate VS Code launch.json (parity surface for IDE users)
bcdock env launch-json "$ENV" --out .vscode/launch.json
```

On a warm pool with a cached vsix, the full loop is ~90 seconds for a small extension.

### Phase 1 — `download-symbols`

Pulls the symbol packages your `app.json` declares from the env's BC `/dev/packages` endpoint. Synthesises the modern split bundle (System Application + Base Application + Business Foundation + Application) from the single `application: <ver>` declaration. 404s on names absent from the env's BC version are silent skips — the package may simply not exist in older / newer BC versions.

```bash
bcdock env download-symbols "$ENV" --out-dir .alpackages
```

**Flags worth knowing:**

| Flag | Default | Notes |
|------|---------|-------|
| `--app-json` | `app.json` | Path to the project manifest |
| `--out-dir` | `.alpackages` | Symbol cache directory |
| `--tenant` | `default` | BC tenant for multi-tenant envs |
| `--force` | `false` | Re-download even if cached |

The cache is content-addressed by version, so a no-op run is cheap (~200ms).

### Phase 2 — `al compile`

Compiles your AL project using the `alc` that ships in the env's bundled `ALLanguage.vsix`. The vsix is fetched once per BC platform version, cached under `~/.cache/bcdock/al-vsix/{platformVersion}/`, and reused across envs on the same platform.

```bash
bcdock al compile --env "$ENV" --out build/MyApp.app
```

First compile per platform version: ~5s (vsix fetch + extract + first alc run). Subsequent compiles: ~2s.

**Flags worth knowing:**

| Flag | Default | Notes |
|------|---------|-------|
| `--env` | _(required)_ | Whose BC platform's alc to use |
| `--project` | `.` | AL project dir (forwarded as `/project:`) |
| `--package-cache` | `.alpackages` | Forwarded as `/packagecachepath:` |
| `--out` | _(alc default)_ | Output `.app` path |
| `--refresh` | `false` | Re-download vsix even if cached |
| `-- /…` | — | Anything after `--` is forwarded verbatim to alc |

For agent loops: pin `--env` to a hibernated env; resume only when you need a publish step. Compile is local — no env round-trip.

### Phase 3 — `env publish`

POSTs the `.app` file to BC's `/dev/apps` endpoint as multipart, with Basic auth from the env's admin password. Synchronous — returns when BC's install/upgrade codeunits finish. Default `--timeout` is 10 minutes.

```bash
bcdock env publish "$ENV" build/MyApp.app
```

**Flags worth knowing:**

| Flag | Default | Notes |
|------|---------|-------|
| `--schema-update-mode` | `synchronize` | `synchronize` \| `forcesync` \| `recreate` (recreate drops table data) |
| `--tenant` | `default` | |
| `--dependency-publishing` | _(server default)_ | `Default` \| `Ignore` \| `Strict` |
| `--timeout` | `10m` | Increase for large extensions with heavy install codeunits |

Publish failures surface BC's error message verbatim on stderr — usually enough to diagnose without opening BC's event log.

### Phase 4 — `env launch-json`

Generates a `.vscode/launch.json` aimed at the env. Useful even if you mostly use the CLI — VS Code's debugger remains the best step-through experience, and the F5 publish path uses the same `/dev/apps` endpoint.

```bash
bcdock env launch-json "$ENV" --out .vscode/launch.json
```

`serverInstance` is derived from the env's `devEndpointUrl` first path segment: `BC-dev` (subdomain mode) or `{containerName}-dev` (path mode). Credentials are **not** written — VS Code prompts on the first publish, the same UX as a hand-configured launch.json.

## Verifying a publish

Two options. **Option A** (`/dev/packages` round-trip) is the strongest signal — same auth as publish, byte-for-byte comparison:

```bash
DEV=$(bcdock env get "$ENV" -o json | jq -r .devEndpointUrl)
PASS=$(bcdock env credentials "$ENV" -o json | jq -r .password)
curl -s -o /tmp/installed.app -w "HTTP %{http_code} bytes=%{size_download}\n" \
    -u "admin:$PASS" \
    "${DEV}dev/packages?publisher=BCDock&appName=MyApp&versionText=1.0.0.0&tenant=default"
diff -q /tmp/installed.app build/MyApp.app   # silent → BC has the same bytes
```

**Option A is the only verification path for a publish.** An earlier version of this page offered an OData `extensions` entity-set as Option B. Measured on prod env `d5b7ac69` (BC 28.4.53241.54101), 2026-09-06: `$metadata` lists 82 published entity sets and `extensions` is not one of them. It answers **404**. Installed extensions are not readable over OData on these environments; use the `/dev/packages` round-trip above.

What OData *is* good for is reading business data, and `bcdock env query` does that in one line without putting a credential on your screen:

```bash
bcdock env query "$ENV" '$metadata'                                    # what this env serves
bcdock env query "$ENV" --company "CRONUS AU" Chart_of_Accounts --top 5
```

`env query` is read-only and fetches the environment's web-service access key itself, so the key never reaches your shell history or your terminal. BC's SOAP and OData surfaces reject the admin password, so the access key is the credential in play here.

If you are reverse-engineering the endpoint rather than using it, the calls underneath are:

```bash
ODATA=$(bcdock env get "$ENV" -o json | jq -r .oDataUrl)
WSKEY=$(bcdock env credentials "$ENV" -o json | jq -r .webServiceAccessKey)

# Cheapest auth+routing probe:
curl -sS -u "admin:$WSKEY" -o /dev/null -w "metadata=%{http_code}\n" \
    "${ODATA}\$metadata?tenant=default"
```

Envs created before 2026-05-04 have `webServiceAccessKey: null` — recreate to backfill, or fall back to Option A.

## Wire URLs (informational)

The CLI handles these — documented for the "reverse-engineer this when bcdock breaks" path:

| Verb | URL constructed |
|------|-----------------|
| `download-symbols` | `GET {devEndpointUrl}dev/packages?publisher=…&appName=…&versionText=…&tenant=…` |
| `env publish` | `POST {devEndpointUrl}dev/apps?SchemaUpdateMode=…&tenant=…` (multipart) |
| `al compile` (vsix fetch) | `GET {downloadsUrl}ALLanguage.vsix` (anonymous, served by every BC container's port 8080) |

`devEndpointUrl` is `{server}/{serverInstance}/` — first path segment is `BC-dev` (subdomain mode) or `{containerName}-dev` (path mode).

## What this replaces

| Old way | New way |
|---|---|
| Install AL VS Code extension globally; keep matched to BC version manually | `bcdock al compile --env <name>` — vsix from the env, version-matched |
| `Publish-NavApp` PowerShell or BcContainerHelper wrapper | `bcdock env publish` — direct multipart to `/dev/apps` |
| Hand-edit `launch.json` per env, paste in URLs and credentials | `bcdock env launch-json --env <name>` |
| Open BC, navigate to "Extension Management" to verify install | `curl /dev/packages` (Option A) or OData `extensions` (Option B) |

The CLI is the API surface — there's no VS Code-only path. The same flow works in CI, in agent loops, and on a developer laptop.

## Next steps

- [GitHub Actions guide](github-actions.md) — same loop, one ephemeral env per PR
- [Claude Code guide](claude-code.md) — agent driving this loop with reasoning between steps
- [CLI reference: env publish](../cli/reference/bcdock_env_publish.md) — every flag, auto-generated from the binary
