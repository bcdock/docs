---
title: Agent scenarios - end-to-end CLI test transcripts
description: Sanitised end-to-end tool-call transcripts for the bcdock CLI. Each scenario is independently runnable; copy-and-adapt for your own agent or scripted test sessions.
---

# Agent scenarios

A collection of end-to-end test scenarios an AI agent (or developer scripting against `bcdock`) can use to validate the BCDock platform. Each scenario is independently runnable - copy the steps, adapt the names, run them.

These scenarios are the best way to understand what `bcdock` actually does end-to-end: real CLI calls, real exit codes, real stdout, real timing. They complement unit and integration tests by exercising the CLI UX and async flows from an outside-in perspective.

## Notation

All scenarios on this page are **[CLI]** only - executable entirely through the `bcdock` CLI against the live BCDock API. No admin access or internal infrastructure required.

## Prerequisites

- **Install the CLI** - see [install guide](install.md).
- **Have a BCDock account and an API key** - see [authentication guide](auth.md).
- No database access, Docker host access, or internal tooling required for any scenario on this page.

## Rules for CLI testing (read first)

1. **One `bcdock` call per tool use.** No shell-script wrappers - they hide the UX friction the run exists to surface.
2. **Discover config at runtime; never hardcode.** `(VERSION, COUNTRY, REGION)` comes from S2's `bcdock artifacts list --fast-only`, persisted to the session env file, and referenced symbolically everywhere else.
3. **Capture stdout + stderr + exit on every probe.** Silent errors are the dominant failure mode - wrap calls with `... > /tmp/p.out 2> /tmp/p.err; echo "exit=$? stdout=[...] stderr=[...]"` so "nothing happened" is distinguishable from "silently passed".
4. **Background long-running commands.** Env create is 25-30 min cold, ~2 min warm. Use `run_in_background: true`, poll status with `bcdock env get`, and run independent scenarios (S1, S2, S5, S6) in parallel during the wait.
5. **Session state goes in a sourced env file.** Include `BCDOCK_TOKEN` and the discovered triple. Every tool use starts with `source /tmp/bcdock-test-tokens.env`.
6. **If a CLI status field looks wrong, re-poll `bcdock env get` after ~5s before assuming a bug.**
7. **Report format**: per-scenario `PASS | FAIL | SKIP` with wall-clock, plus a friction notes section so individual CLI bugs get filed without drowning the pass/fail signal.

---

## S1 - Sign in and verify identity

**Goal**: Confirm the CLI is authenticated and targets the correct API.

**Steps**:

1. `bcdock auth whoami -o json`
2. `bcdock companies list -o json`

**Accept if**:

- `whoami` returns HTTP 200 with your authenticated email address and a non-empty `companyName`.
- `companies list` returns ≥1 company containing the company from `whoami`.

**Fail modes to probe**:

- Unset `BCDOCK_TOKEN` and clear `~/.bcdock/credentials.json`. Rerun `whoami`. Expect non-zero exit and a message naming `auth set-token` or `BCDOCK_TOKEN`.

**Note**: If you belong to multiple companies, `bcdock companies list` + `bcdock companies switch` will work - there is no agent-friendly multi-company seed scenario on this page, but both commands are exercisable independently.

---

## S2 - Discover a valid environment configuration

**Goal**: Produce a `(VERSION, COUNTRY, REGION)` triple dynamically for S3+. **Never hardcode a version.** Pre-built images churn as BC releases; a hardcoded triple rots into a ~78-min image build.

**Steps**:

1. `bcdock config regions -o json` - pick a `REGION` (e.g. first entry).
2. `bcdock artifacts list --region "$REGION" --fast-only -o json` - pick the first row where `hasVmImage == true && isPreview == false`. Extract `version` and `country`.
3. Persist to the session env file so S3+ use the same triple:
   ```bash
   ROW=$(bcdock artifacts list --region "$REGION" --fast-only -o json \
       | jq -r '[.[] | select(.hasVmImage == true and .isPreview == false)][0]')
   VERSION=$(echo "$ROW" | jq -r .version)
   COUNTRY=$(echo "$ROW" | jq -r '.country // "AU" | ascii_downcase')
   printf 'VERSION=%s\nCOUNTRY=%s\nREGION=%s\n' "$VERSION" "$COUNTRY" "$REGION" \
       >> /tmp/bcdock-test-tokens.env
   ```

**Accept if**:

- Each command exits 0.
- `VERSION`, `COUNTRY`, `REGION` are all non-empty and `$ROW` is not `null`.

**If `--fast-only` returns empty for your first region**: try another region from step 1 before giving up. If every region is empty, stop and report - don't fall through to a version that requires an image build.

---

## S3 - Happy-path environment lifecycle

**Goal**: End-to-end CRUD through the CLI.

**Wall clock**: ~25-30 min on cold stack (pool auto-creation path). ~2 min on warm pool.

`bcdock env create` triggers the pool autoscaler, which creates a pool automatically if none matching the requested `(version, country, region)` exists - no manual pool setup needed.

**Use a timestamp-suffixed name** to avoid collisions across re-runs and to make dangling resources from aborted runs trivially identifiable:

```bash
ENV_NAME=agent-e2e-$(date +%s)
```

**Steps**:

1. Confirm name is free: `bcdock env list -o json | jq --arg n "$ENV_NAME" '.[] | select(.name==$n)'` - expect empty.
2. Create - **use the triple from S2, never hardcoded values**. Background the call so parallel scenarios can run during the wait:
   ```bash
   source /tmp/bcdock-test-tokens.env   # loads VERSION/COUNTRY/REGION from S2
   bcdock env create --name "$ENV_NAME" --version "$VERSION" \
     --country "$COUNTRY" --region "$REGION" --wait --wait-timeout 40m \
     > /tmp/bcdock-env-create.out 2> /tmp/bcdock-env-create.err &
   ```
   Poll progress with `bcdock env get "$ENV_NAME" -o json | jq '{status, provisioningPercent, provisioningStage}'` - never by tailing the backgrounded process.
3. While step 2 runs, execute scenarios that don't need a running env: **S2, S5, S6**.
4. Once status is `running`: inspect `bcdock env get "$ENV_NAME" -o json` - read `status`, `webClientUrl`, `shortId`.
5. List filter: `bcdock env list --status running -o json` - env appears.
6. Resolve by shortId: `bcdock env get <shortId> -o json` - same env.
7. Run env-dependent scenarios: **S4 (logs), S7 (hibernate/resume), S8 (AL extension loop)**.
8. Delete: `bcdock env delete "$ENV_NAME" --force --wait --wait-timeout 5m`
9. Confirm gone: `bcdock env get "$ENV_NAME" -o json` - expect exit 5 or `status == "deleted"`.

**Accept if**:

- After step 4, status is `running` and `webClientUrl` is non-null.
- After step 8, `bcdock env get "$ENV_NAME"` exits with code 5 or returns `status == "deleted"`.

**Tool surface to exercise**:

- Try `-o table` and `-o csv` on all read commands.
- Omit a required flag on `create` and confirm the error names the missing flag.

**Note**: `env list -o json` returns `version: null` for envs still in `pending-pool` / `queued`. Version is populated only after pool assignment.

---

## S4 - Logs

**Prerequisites**: A running environment (reuse `$ENV_NAME` from S3, or create a fresh one).

**Goal**: Exercise all log modes.

**Steps**:

1. `bcdock env logs "$ENV_NAME" --tail 50`
2. `timeout 10 bcdock env logs "$ENV_NAME" --follow` - stream; expect ≥1 line before timeout.
3. `bcdock env logs "$ENV_NAME" --provisioning` - provisioning history.

**Accept if**:

- Step 1: ≥1 line on stdout.
- Step 2: ≥1 line emitted, exits cleanly on SIGTERM.
- Step 3: lines contain provisioning milestones (`pool`, `container`, `Ready`).

**Note**: Logs route through the pool agent running on the Azure VM. If the pool is healthy but step 1 returns empty, retry after 5s.

**Note**: Live stats streaming via `bcdock env stats` is not yet shipped - open an issue if you need it.

---

## S5 - Usage reporting

**Prerequisites**: At least one environment has existed (deleted is fine - usage is retained).

**Steps**:

1. `bcdock usage -o json`
2. `bcdock usage --by-environment -o json`
3. `bcdock usage --from 2026-04-01 --to 2026-04-30 -o csv`
4. `bcdock env usage "$ENV_NAME" -o json`

**Accept if**:

- All commands exit 0.
- CSV has a header row and ≥1 data row for a month with activity.
- Per-env total in (2) ≤ company total in (1) for the same window.

---

## S6 - Error paths and CLI UX

**Goal**: Confirm the CLI fails loudly with actionable messages.

**Probes** (each must exit non-zero and not hang):

| # | Command | Expected failure |
|---|---|---|
| 1 | `bcdock env create --name x` | Missing required flags named in error |
| 2 | `bcdock env create --name x --version 99.99 --country au --region westus2 --wait --wait-timeout 30s` | 4xx from API; error surfaced, no hang |
| 3 | `bcdock env get does-not-exist` | Exit 5, "not found" |
| 4 | `bcdock env delete does-not-exist --force` | Exit 5 or clear error |
| 5 | `BCDOCK_TOKEN=invalid bcdock env list` | 401; "unauthorized" or equivalent |
| 6 | `bcdock env create --name x --version 28.0.46665.49375 --country au --region bogusregion --wait --wait-timeout 30s` | Invalid region rejected |

**Report**: For each probe, record exit code, stderr excerpt, and whether the message was actionable. Unclear or missing messages are CLI bugs worth filing.

---

## S7 - Hibernate and resume

**Prerequisites**: A running environment (create one via S3 if needed).

**Steps**:

1. Confirm baseline:
   ```bash
   bcdock env get "$ENV_NAME" -o json | jq .status   # expect: "running"
   ```
2. Hibernate:
   ```bash
   bcdock env hibernate "$ENV_NAME" --wait --wait-timeout 5m
   ```
3. Confirm hibernated:
   ```bash
   bcdock env get "$ENV_NAME" -o json | jq '{status, webClientUrl}'
   # expect: status == "hibernated"
   ```
4. Resume:
   ```bash
   bcdock env resume "$ENV_NAME" --wait --wait-timeout 10m
   ```
5. Confirm running:
   ```bash
   bcdock env get "$ENV_NAME" -o json | jq '{status, webClientUrl}'
   # expect: status == "running", webClientUrl non-null
   ```

**Accept if**: All status checks match expectations above.

**Progress surface**: During hibernate and resume, `provisioningStage` / `provisioningProgressPercent` on `bcdock env get -o json` are expected to advance monotonically. Spot-check at least one intermediate stage (`StoppingBc`, `BackingUpDb`, `UploadingBackup`, `StartingSQL`, etc.) while the flow is running. If the CLI reports `[resuming] complete (100%)` instantly, treat it as a bug.

**Fail modes to probe**:

- Hibernate an already-hibernated env - expect 4xx with actionable error.
- Resume a running env - expect 4xx with clear message.
- `bcdock env hibernate does-not-exist --wait` - expect exit 5.

**Version upgrade probe**:

```bash
bcdock env resume "$ENV_NAME" --version 28.0.46665.49375 --wait
# Same version → succeeds (no-op upgrade confirmation)
```

---

## S8 - AL extension install loop

**Prerequisites**: A running environment from S3.

**Goal**: Exercise the four-phase developer loop entirely from the CLI - no VS Code, no global `al` install, no curl against `/dev/*`. Validates the end-to-end surface: `env download-symbols` -> `al compile --env` -> `env publish`, with `env launch-json` for VS Code parity.

**Wall clock** (BC 28, B2ms pool): download-symbols ≤5s · compile ~8s (vsix cache hit) · publish 37-52s · total <90s for the loop after the env reaches `running`. First-ever compile on a new platform version pays an extra ~5s for the `ALLanguage.vsix` download + extract (one-time per platform version).

**Endpoint overview** - what each surfaced env URL actually accepts:

| Endpoint | Anonymous | Basic auth |
|---|---|---|
| `webClientUrl` | 302 to sign-in page | 200 welcome page (`admin:password`) |
| `devEndpointUrl` | n/a | 200 for `dev/metadata`, `dev/apps`, `dev/packages` (`admin:password`) |
| `downloadsUrl` + `ALLanguage.vsix` | 200 octet-stream | n/a |
| `soapUrl` | 401 SOAP fault | 200 with `admin:webServiceAccessKey` |
| `oDataUrl` | 401 | 200 with `admin:webServiceAccessKey` |

`webClientUrl` and `downloadsUrl` are anonymous; `devEndpointUrl` uses Basic auth with `admin:password`; `soapUrl` and `oDataUrl` use Basic auth with `admin:webServiceAccessKey` (the key is minted during provisioning; read it with `bcdock env credentials <env>`, which no longer rides along on `bcdock env get`).

**Steps**:

1. Scaffold a minimal AL project. Pin `platform` / `application` to the env's actual major (read from `bcdock env get`); trailing build numbers are fine as `0.0` because BC's `/dev/packages` matches by minimum version:
   ```bash
   PROJ=/tmp/agent-al-$(date +%s); mkdir -p "$PROJ/src"
   PV=$(bcdock env get "$ENV_NAME" -o json | jq -r .platformVersion | cut -d. -f1).0.0.0
   cat > "$PROJ/app.json" <<EOF
   {
     "id":"00000000-1111-2222-3333-444444444444",
     "name":"AgentSmoke","publisher":"BCDock","version":"1.0.0.0",
     "platform":"$PV","application":"$PV",
     "idRanges":[{"from":50100,"to":50149}],
     "runtime":"16.0","target":"OnPrem"
   }
   EOF
   cat > "$PROJ/src/CustomerPageExt.al" <<'EOF'
   pageextension 50101 "Agent Smoke Customer Ext" extends "Customer List"
   {
       trigger OnOpenPage()
       begin
           Message('Hello from BCDock!');
       end;
   }
   EOF
   ```

2. Pull symbols from the env:
   ```bash
   bcdock env download-symbols "$ENV_NAME" \
       --app-json "$PROJ/app.json" --out-dir "$PROJ/.alpackages"
   ```
   On modern BC (23+), expect **5 packages**: `Microsoft_System Application`, `Microsoft_Base Application`, `Microsoft_Business Foundation`, `Microsoft_Application` (legacy bundle, still served alongside), and `Microsoft_System`. The CLI fetches all with `Optional=true` so any 404s on older BC versions are silent skips.

3. Compile with the env-matched alc (extracted from the env's bundled `ALLanguage.vsix`, cached under `~/.cache/bcdock/al-vsix/{platformVersion}/`):
   ```bash
   bcdock al compile --env "$ENV_NAME" \
       --project "$PROJ" \
       --package-cache "$PROJ/.alpackages" \
       --out "$PROJ/build/AgentSmoke.app"
   ```

4. Publish:
   ```bash
   bcdock env publish "$ENV_NAME" "$PROJ/build/AgentSmoke.app"
   ```

5. **Verify by round-trip via `/dev/packages`** - ask BC to serve back the package you just published. If the bytes match, install succeeded:
   ```bash
   DEV=$(bcdock env get "$ENV_NAME" -o json | jq -r .devEndpointUrl)
   PASS=$(bcdock env credentials "$ENV_NAME" -o json | jq -r .password)
   curl -s -o /tmp/installed.app -w "HTTP %{http_code} bytes=%{size_download}\n" \
       -u "admin:$PASS" \
       "${DEV}dev/packages?publisher=BCDock&appName=AgentSmoke&versionText=1.0.0.0&tenant=default"
   diff -q /tmp/installed.app "$PROJ/build/AgentSmoke.app"  # silent → identical
   ```

6. **Generate VS Code launch.json** (the parity surface for users who want IDE support):
   ```bash
   bcdock env launch-json "$ENV_NAME" --out "$PROJ/.vscode/launch.json"
   jq '.configurations[0] | {server, serverInstance, authentication, tenant}' \
       "$PROJ/.vscode/launch.json"
   # subdomain envs: serverInstance == "BC-dev"
   # path-mode envs: serverInstance == "{name}-dev"
   ```

**Accept if**:

- Each step exits 0.
- `download-symbols` says "(5 downloaded, 0 skipped)" on a fresh modern-BC env's first run, and "(0 downloaded, 5 skipped)" on re-run without re-fetching.
- `al compile` produces the `.app`. Second invocation against an env on the same `platformVersion` reuses the cached vsix (no second vsix download line).
- `env publish` exits 0 within the default 10m. Step 5's diff is silent.
- `env launch-json` emits valid JSON; `serverInstance` is the first path segment of the env's `devEndpointUrl` (`BC-dev` for subdomain, `{name}-dev` for path mode).

**Re-run / iteration probe** (validates the actual dev loop, not just the first deploy):

1. Edit `CustomerPageExt.al` to change the message text.
2. Bump `version` in `app.json` (e.g. `1.0.0.0` -> `1.0.1.0`) - BC rejects a re-publish at the same version (see fail modes).
3. Re-run steps 3-4. Both should be noticeably faster than the first run (alc cache hit, symbols cache hit, no vsix re-extract).

**Fail modes to probe**:

- Forgot to bump the version → `env publish` returns 4xx with "already published" - the CLI must surface BC's message verbatim, not swallow it.
- `--schema-update-mode recreate` on a real env should print a destructive warning before BC drops table data; verify a `--yes` or confirmation is required.
- Missing `app.json` field (e.g. drop `idRanges`) → `al compile` fails with alc's diagnostic on stderr; `bcdock`'s exit code should match alc's.

---

## S9 - Customer journey backbone (signup → login → billing → account close)

**Prerequisites**: No env or pool required.

**Goal**: Validate the customer-journey spine end-to-end: account creation via invite code, login, billing snapshot, and account deletion round-trip.

**Steps**:

1. **Sign up**: visit [https://bcdock.io](https://bcdock.io) to request access, or skip to step 2 if you already have an invite code. Invite codes are emailed by BCDock when your waitlist entry is approved.

2. **Activate account** (requires invite code):
   ```bash
   EMAIL="journey-$(date +%s)@example.com"
   bcdock auth signup --invite-code <code> --email "$EMAIL" --accept-eula
   # → "Account activated. A welcome email has been sent to ..."
   ```

3. **Login via OTP**:
   ```bash
   bcdock auth login --email "$EMAIL"
   # → CLI prompts for the OTP code sent to your email
   ```
   `bcdock auth login` persists an API key to `~/.bcdock/credentials.json`; subsequent commands pick it up automatically. There is no separate JWT mint step for normal customer scenarios.

   For non-interactive / scripted flows, pass `--otp <code>` directly: `bcdock auth login --email "$EMAIL" --otp <code>`.

4. **Billing snapshot**:
   ```bash
   bcdock me billing show -o json | jq '{tier:.plan.tier, sub:.subscription, invoices:(.invoices|length)}'
   # expect: {"tier":"free_trial","sub":null,"invoices":0}
   ```

5. **Schedule + cancel deletion** (round-trip):
   ```bash
   bcdock me delete --confirm "$EMAIL"
   bcdock me show -o json | jq -r .status   # → deletion_requested
   bcdock me cancel-deletion
   bcdock me show -o json | jq -r .status   # → active
   ```

**Accept if**: CLI steps (2-5) each exit 0; the trial billing snapshot returns `tier=free_trial / sub=null / invoices=0`; the deletion round-trip flips status `active → deletion_requested → active`.

---

## S10 - Trial → paid Stripe Checkout URL

**Prerequisites**: A trial user token from S9 (the `bdk_...` token in `~/.bcdock/credentials.json`).

**Goal**: Validate the Stripe Checkout URL minting path. Full payment completion requires a browser, but the BCDock-side handoff (lookup plan → ensure Stripe Customer → create Checkout Session → return URL) is testable from the CLI alone.

**Steps**:

1. **Mint checkout URL** (currency must be **uppercase** - the API does a case-sensitive lookup):
   ```bash
   bcdock me billing checkout --tier starter --currency AUD -o json | jq -r .url
   # → https://checkout.stripe.com/c/pay/cs_test_...
   ```

2. **Optional - confirm URL is live**:
   ```bash
   curl -sI "$URL" -o /dev/null -w "%{http_code}\n"   # → 200
   ```

**Accept if**: Step 1 returns a `checkout.stripe.com` URL. Step 2 returns 200.

**Fail modes**:

- Lowercase `--currency aud` → `400 invalid_state: No active SubscriptionPlan for tier=starter currency=aud` (case-sensitivity gap; CLI does not normalize currency case).
- HTTP 500 on step 1 → indicates a payment configuration issue, not a BCDock bug. [File an issue](https://github.com/bcdock/cli/issues) with the full error response.

---

## Execution techniques

### Background long-running scenarios; run independent ones in parallel

S3 env-create is 25-30 min on a cold stack. Blocking serially on it wastes the agent's session. Classify scenarios as **gated on env** vs **independent**, and schedule accordingly:

| Gated on running env | Independent (run during S3 wait) |
|---|---|
| S4 (logs), S7 (hibernate/resume), S8 (AL install loop), S3 teardown | S1, S2, S5, S6 |

Fire S3's `env create` with `run_in_background: true`, then immediately start the independent column. Poll S3 between batches via `bcdock env get` - **not** by tailing the backgrounded process.

### Persist session state in a sourced env file

Don't re-mint tokens per tool call. Write once, source everywhere:

```bash
cat > /tmp/bcdock-test-tokens.env <<EOF
BCDOCK_TOKEN=$BCDOCK_TOKEN
ENV_NAME=agent-e2e-$(date +%s)
EOF
# S2 appends VERSION/COUNTRY/REGION to this file.
# Subsequent calls:
source /tmp/bcdock-test-tokens.env && bcdock env get "$ENV_NAME" -o json
```

### One CLI call per tool use - never wrap in a script

Each `bcdock` invocation is its own agent action. Wrapping them in a shell script hides the CLI UX (unclear errors, exit-code inconsistency, JSON shape surprises) - and those are exactly what agent scenarios exist to surface. If something needs to happen atomically, it is a platform bug, not a test harness opportunity.

### Verify a publish: /dev/packages round-trip vs OData

Two ways to verify a published app - pick whichever fits the check you actually want.

**Option A - `/dev/packages` round-trip** (strongest signal, no access key needed):

Ask BC's dev endpoint to serve back the exact package bytes you uploaded:

```bash
DEV=$(bcdock env get "$ENV_NAME" -o json | jq -r .devEndpointUrl)
PASS=$(bcdock env credentials "$ENV_NAME" -o json | jq -r .password)
curl -s -o /tmp/installed.app -w "HTTP %{http_code} bytes=%{size_download}\n" \
    -u "admin:$PASS" \
    "${DEV}dev/packages?publisher=BCDock&appName=AgentSmoke&versionText=1.0.0.0&tenant=default"
diff -q /tmp/installed.app "$PROJ/build/AgentSmoke.app"   # silent → success
```

**Option B - read business data over OData** (the public web service):

> Installed extensions are **not** readable over OData here. Measured on prod env `d5b7ac69` (BC 28.4.53241.54101), 2026-09-06: `$metadata` lists 82 published entity sets and `extensions` is not one of them. It answers **404**. Use Option A to verify a publish.

`bcdock env query` runs the read for you and never puts the credential on your screen; the raw calls are below it for the reverse-engineering path. SOAP and OData accept Basic auth as `admin:webServiceAccessKey`, which comes from `bcdock env credentials`.

```bash
# The CLI path - read-only, one audited credential fetch, nothing secret on screen:
COMPANY=$(bcdock env query "$ENV_NAME" Company -o json | jq -r '.[0].Name')
bcdock env query "$ENV_NAME" --company "$COMPANY" Chart_of_Accounts --select "No,Name" --top 5
```

The same thing at the wire level, for when you are working out what the CLI is doing:

```bash
ODATA=$(bcdock env get "$ENV_NAME" -o json | jq -r .oDataUrl)
WSKEY=$(bcdock env credentials "$ENV_NAME" -o json | jq -r .webServiceAccessKey)

# Smoke test: $metadata is the cheapest "auth + routing OK" probe
curl -sS -u "admin:$WSKEY" -o /dev/null -w "metadata=%{http_code}\n" \
    "${ODATA}\$metadata?tenant=default"

# List companies
curl -sS -u "admin:$WSKEY" "${ODATA}Company?tenant=default" | jq '.value[].Name'

# List installed extensions (URL-encode company names with spaces/punctuation:
# "CRONUS Australia Pty. Ltd." → Company('CRONUS%20Australia%20Pty.%20Ltd.'))
COMPANY=$(curl -sS -u "admin:$WSKEY" "${ODATA}Company?tenant=default" \
    | jq -r '.value[0].Name' | jq -sRr @uri)
curl -sS -u "admin:$WSKEY" \
    "${ODATA}Company('${COMPANY}')/$metadata?tenant=default"   # the entity sets this env serves
```

---

## Scenario selection by context

| Context | Recommended scenarios |
|---|---|
| First run | S1 → S2 → S3 (background) ∥ S5, S6 → S4, S7, S8 → S3 teardown |
| Full validation | S1 → S2 → S3 (background) ∥ S5, S6 → S4, S7, S8 → S3 teardown |
| After CLI change | S1, S3, S4, S6, S7, S8, S9 |
| Hibernate/resume work | S3 → S7 |
| AL extension loop | S2 → S3 → S8 |
| Billing and usage | S5, S9, S10 |
| Customer journey end-to-end | S9 → S10 |
| Error UX audit | S6 in depth |

---

## Reporting

For each scenario:

```
S<n> - <one-line name>
  Result: PASS | FAIL | SKIP
  Exit codes: <per step>
  Notable output: <stderr or JSON field that failed>
  Time: <wall clock>
  Friction: <ambiguous errors, missing commands, unexpected hangs>
```

The friction section is the primary deliverable. Scripted tests already verify the happy path; agent runs expose UX gaps and real-world edge cases.

---

## Where to file CLI bugs

[https://github.com/bcdock/cli/issues](https://github.com/bcdock/cli/issues)
