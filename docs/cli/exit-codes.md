---
title: CLI exit codes
description: Stable, documented exit codes for bcdock. What each code means, what an agent or script should do in response.
---

# Exit codes

Scripts and agents rely on exit codes - they must be stable and documented. The CLI never re-uses a code for a different meaning across versions.

| Code | Meaning | Recovery |
|---|---|---|
| `0` | Success | Continue |
| `1` | General error: an API error, invalid input or a usage error, a failed provisioning, or a `--wait` on `env create` / `resume` / `hibernate` that timed out | Read stderr; surface the message to the caller. For a provisioning failure: `bcdock env logs <name> --provisioning` |
| `2` | Reserved - not emitted today | - |
| `3` | Authentication failure (expired/missing/invalid token) | Re-authenticate: `bcdock auth login`, or refresh `BCDOCK_TOKEN` from the secret store |
| `4` | Rate limited (HTTP 429) | Back off and retry (exponential, jitter); honour any `Retry-After` header surfaced in stderr |
| `5` | Resource not found (env name doesn't exist, etc.) | Verify the name/short ID; in agent flows, list first then act |
| `10` | Reserved - not emitted today. A provisioning failure exits `1` | - |
| `124` | A wait gave up: `bcdock env wait` did not see a requested status (`--timeout` elapsed, or the environment reached a terminal status you did not ask for), or `bcdock me export --wait` timed out | Check the resource's state (`bcdock env get <name>`); increase the timeout if it is still in progress |

## Error shape on stderr

When the CLI exits non-zero, it writes a single human-readable line to stderr:

```
error: invalid_state: Only running environments can be hibernated (current status: hibernated).
```

With `-o json`, it writes **one JSON object** to stderr instead, so your script or agent can act on the failure without parsing text:

```json
{"error":"invalid_state","message":"invalid_state: Only running environments can be hibernated (current status: hibernated).","exitCode":1,"status":400}
```

When the API sends no code of its own, `error` is derived from the HTTP status, and `message` carries the response as the CLI received it:

```json
{"error":"not_found","message":"HTTP 404: {\"type\":\"https://tools.ietf.org/html/rfc9110#section-15.5.5\",\"title\":\"Not Found\",\"status\":404,\"traceId\":\"00-...\"}","exitCode":5,"status":404}
```

| Field | Meaning |
|---|---|
| `error` | A stable code to branch on (see below) |
| `message` | The same text the human-readable line shows |
| `exitCode` | The process exit code, the same as in every other output format |
| `status` | The HTTP status, present only when the failure came from the API |

The `error` code is the API's own code when it sent one, for example `not_found`, `invalid_state`, `invalid_input` or `quota_exceeded`. Otherwise it is one of:

| `error` | When |
|---|---|
| `unauthorized`, `forbidden`, `not_found`, `rate_limited`, `internal_error`, `service_unavailable` | The API failed with that HTTP status and sent no code |
| `api_error` | Any other API failure with no code |
| `timeout` | A wait gave up (exit `124`): `bcdock env wait`, or `bcdock me export --wait` |
| `network` | The request did not complete: connection refused, DNS, TLS, or the request timed out |
| `cli_error` | Anything else the CLI rejected before or after calling the API, such as invalid input or an unreadable file |

stdout stays empty on failure, so `bcdock ... -o json | jq` never receives the error. One deliberate exception: when `bcdock env create --manifest` creates the environment but an app fails to publish, it still prints the environment record to stdout, because the environment exists and you need its id to retry or delete it.

```bash
if ! bcdock env hibernate "$ENV" -o json 2>err.json; then
    case "$(jq -r .error err.json)" in
        invalid_state) echo "Not running, nothing to hibernate";;
        not_found)     echo "No such environment";;
        *)             jq -r .message err.json; exit 1;;
    esac
fi
```

## Patterns

### Bash - fail fast

```bash
set -euo pipefail
bcdock env create --name ci-test --version 27 --country au --wait
# If create fails (any non-zero exit), the script aborts here.
```

### Bash - handle a specific code

```bash
if ! bcdock env get "$ENV"; then
    case $? in
        3) echo "Auth expired, re-running login..."; bcdock auth login;;
        5) echo "Env $ENV doesn't exist yet, creating..."; bcdock env create --name "$ENV" --wait;;
        *) echo "Unexpected failure"; exit 1;;
    esac
fi
```

### Agent loop - wait with backoff

```bash
# Wait up to 30 min for the env to be running.
# Exit 0 = ready; exit 124 = timed out; exit 5 = name typo.
bcdock env wait "$ENV" --status running --status failed --timeout 30m
case $? in
    0) echo "Env reached terminal state - check status";;
    5) echo "Env name not found, exiting"; exit 1;;
    124) echo "Timed out, escalating to human"; exit 1;;
esac
```

### CI - surface the failure cleanly

```bash
bcdock env publish "$ENV" build/MyApp.app || {
    echo "::error::publish failed (exit $?)"
    bcdock env logs "$ENV" --provisioning
    exit 1
}
```

## What's not here

- **HTTP status codes as exit codes** - the CLI translates 401/403 → `3`, 404 → `5`, 429 → `4`, 5xx → `1`. With `-o json`, the error object also carries the HTTP status in `status`.
- **`--quiet` and exit codes** - `--quiet` only suppresses stdout. Exit codes are unaffected; `set -e` still works.

## Source of truth

The CLI binary defines and emits these codes; this table is the human-readable summary. Adding a new code in a CLI release also adds a row here.
