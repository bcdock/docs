---
title: CLI exit codes
description: Stable, documented exit codes for bcdock. What each code means, what an agent or script should do in response.
---

# Exit codes

Scripts and agents rely on exit codes — they must be stable and documented. The CLI never re-uses a code for a different meaning across versions.

| Code | Meaning | Recovery |
|---|---|---|
| `0` | Success | Continue |
| `1` | General error (API error, invalid input, unexpected failure) | Read stderr; surface the message to the caller |
| `2` | Operation still in progress when `--wait-timeout` elapsed | Increase the timeout, or poll status manually with `bcdock env get` / `bcdock env wait` |
| `3` | Authentication failure (expired/missing/invalid token) | Re-authenticate: `bcdock auth login`, or refresh `BCDOCK_TOKEN` from the secret store |
| `4` | Rate limited (HTTP 429) | Back off and retry (exponential, jitter); honour any `Retry-After` header surfaced in stderr |
| `5` | Resource not found (env name doesn't exist, etc.) | Verify the name/short ID; in agent flows, list first then act |
| `10` | Provisioning failed (env create/delete/hibernate/resume reached a terminal `failed` state) | Read provisioning logs: `bcdock env logs <name> --provisioning` |
| `124` | Wait/poll timeout (`bcdock env wait --timeout` elapsed without matching any requested status) | Same as `2` but specific to `env wait` |

## Error shape on stderr

When the CLI exits non-zero, it writes a single human-readable line to stderr:

```
error: environment not found: my-typo-env
```

A structured-JSON error envelope is in flight; until it ships, parse the exit code and treat stderr as opaque human text.

## Patterns

### Bash — fail fast

```bash
set -euo pipefail
bcdock env create --name ci-test --version 27 --country au --wait
# If create fails (any non-zero exit), the script aborts here.
```

### Bash — handle a specific code

```bash
if ! bcdock env get "$ENV"; then
    case $? in
        3) echo "Auth expired, re-running login..."; bcdock auth login;;
        5) echo "Env $ENV doesn't exist yet, creating..."; bcdock env create --name "$ENV" --wait;;
        *) echo "Unexpected failure"; exit 1;;
    esac
fi
```

### Agent loop — wait with backoff

```bash
# Wait up to 30 min for the env to be running.
# Exit 0 = ready; exit 124 = timed out; exit 5 = name typo.
bcdock env wait "$ENV" --status running --status failed --timeout 30m
case $? in
    0) echo "Env reached terminal state — check status";;
    5) echo "Env name not found, exiting"; exit 1;;
    124) echo "Timed out, escalating to human"; exit 1;;
esac
```

### CI — surface the failure cleanly

```bash
bcdock env publish "$ENV" build/MyApp.app || {
    echo "::error::publish failed (exit $?)"
    bcdock env logs "$ENV" --provisioning
    exit 1
}
```

## What's not here

- **HTTP status codes** — we don't expose those directly. The CLI translates 401/403 → `3`, 404 → `5`, 429 → `4`, 5xx → `1`.
- **`--quiet` and exit codes** — `--quiet` only suppresses stdout. Exit codes are unaffected; `set -e` still works.

## Source of truth

The CLI binary defines and emits these codes; this table is the human-readable summary. Adding a new code in a CLI release also adds a row here.
