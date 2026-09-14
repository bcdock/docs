---
title: GitHub Actions — ephemeral BC environments per pull request
description: Spin up a fresh BC environment on PR open, publish your extension, run tests, tear down on close. Complete workflow template.
schema_type: HowTo
---

# GitHub Actions

Goal: every PR gets a fresh BC environment, the extension built from the PR branch is published into it, your tests run against it, and it tears down when the PR closes. Provisioning the env is the long step (~7-15 minutes on a warm pool); compile + publish + test runs in the minutes after.

## Prerequisites

- A `BCDOCK_TOKEN` in your repo's GitHub secrets (`Settings → Secrets and variables → Actions → New repository secret`). Mint from `app.bcdock.io/profile/api-keys` with `env:read` + `env:write` scopes.
- A `bcdock.yaml` at the repo root (optional but recommended) so flag defaults don't have to repeat across jobs.
- The CLI installed in your action runner — easiest path is the [`bcdock/setup-cli@v1`](https://github.com/bcdock/setup-cli) action (when it ships) or the install script.

## Workflow template

Save as `.github/workflows/bcdock-pr.yml`:

```yaml
name: BC test environment

on:
  pull_request:
    types: [opened, synchronize, closed]
    branches: [main]

# Each PR gets its own env; new pushes to the same PR reuse it.
concurrency:
  group: bcdock-pr-${{ github.event.pull_request.number }}
  cancel-in-progress: false

env:
  ENV_NAME: pr-${{ github.event.pull_request.number }}
  BCDOCK_TOKEN: ${{ secrets.BCDOCK_TOKEN }}

jobs:
  provision-and-test:
    if: github.event.action != 'closed'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install bcdock
        run: curl -fsSL https://cli.bcdock.io/install.sh | sh

      - name: Create or resume environment
        run: |
          if bcdock env get "$ENV_NAME" -o json >/dev/null 2>&1; then
            # PR already has an env — make sure it's running
            bcdock env resume "$ENV_NAME" --wait || true
          else
            bcdock env create --name "$ENV_NAME" --version 27 --country au --wait \
              --wait-timeout 30m
          fi

      - name: Pull AL symbols
        run: bcdock env download-symbols "$ENV_NAME" --out-dir .alpackages

      - name: Compile extension
        run: bcdock al compile --env "$ENV_NAME" --out build/MyExtension.app

      - name: Publish into BC
        run: bcdock env publish "$ENV_NAME" build/MyExtension.app

      - name: Run AL tests
        # TODO: wire your test runner here. BCDock doesn't ship a generic
        # "run all AL tests" verb yet — `bcdock env test` is on the CLI
        # roadmap. Concrete options today:
        #   1. Publish a separate `MyApp.Tests.app` extension that exposes
        #      a webservice-callable codeunit; invoke it via OData using
        #      `webServiceAccessKey` from `bcdock env get -o json`.
        #   2. Use the BC Test Tool page from a smoke script.
        #   3. Skip CI tests until `bcdock env test` ships and run AL tests
        #      locally via VS Code's AL Test Runner.
        # Until then, this step is a placeholder.
        run: echo "(no AL tests wired — see TODO above)"

      - name: Comment env URL on PR
        uses: actions/github-script@v7
        with:
          script: |
            const url = require('child_process')
              .execSync(`bcdock env get ${process.env.ENV_NAME} -o json`)
              .toString();
            const env = JSON.parse(url);
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: `BC environment ready: ${env.webClientUrl}\n\nLogin: \`Administrator\` / see \`bcdock env get ${env.name}\``
            });

      - name: Hibernate when done (drops billing to the stored rate)
        if: always()
        run: bcdock env hibernate "$ENV_NAME" --wait || true

  teardown:
    if: github.event.action == 'closed'
    runs-on: ubuntu-latest
    steps:
      - name: Install bcdock
        run: curl -fsSL https://cli.bcdock.io/install.sh | sh

      - name: Delete environment
        run: bcdock env delete "$ENV_NAME" --force --wait || true
```

## Patterns worth knowing

### Hibernate, don't delete, between pushes

A PR with 10 pushes to the same branch = 10 workflow runs. If each run creates a fresh env, you pay ~10 active provisions + 10 deletions. Hibernating between runs and resuming on the next push:

- Same active runtime per run (the env is running while tests are)
- Between runs, the env sits at the much-lower stored rate
- Resuming a hibernated env is faster than a cold create from scratch

The template above does this with the `bcdock env get … || bcdock env create …` pattern.

### Concurrency group per PR

```yaml
concurrency:
  group: bcdock-pr-${{ github.event.pull_request.number }}
  cancel-in-progress: false
```

Without this, a fast `git push` followed by `git push --force` can run two jobs in parallel that both try to publish the same extension into the same env. The second one wins but the first wastes pool time and may corrupt the package state mid-install.

### Don't fail the whole job on hibernate failure

```yaml
- name: Hibernate when done
  if: always()
  run: bcdock env hibernate "$ENV_NAME" --wait || true
```

The `|| true` swallows the exit code. A failed hibernate (env already in `failed` state, etc.) shouldn't mark the test job red — that's a billing concern, not a test result. The `if: always()` guarantees the step runs even when an earlier step failed.

### Per-PR teardown on close

The `teardown` job triggers on `closed` (whether merged or abandoned). If a PR sits closed without teardown, you keep paying the stored rate until manually cleaned up — the autoscaler doesn't garbage-collect customer envs.

For very long-lived PRs (multi-week WIP branches), you might want **scheduled hibernate**:

```yaml
on:
  schedule:
    - cron: '0 18 * * *'  # 6pm UTC daily
```

## Secret hygiene

- **Never** print `BCDOCK_TOKEN` to logs. GitHub auto-masks anything matching `secrets.*`, but a `set -x` or accidental `echo` defeats that.
- **Scope the token narrowly** — `env:write` is enough for the standard loop; don't add scopes the workflow doesn't actually use.
- **Rotate** when contributors leave. The portal's API keys page lets you revoke a single key without touching others.
- **One token per repo**, not one per CI vendor. Reduces blast radius and makes audit log entries easy to attribute.

## Cost shape

For a busy team running per-PR environments, the typical workload looks like:

- **Active runtime is short.** ~5 min per push, ~3 pushes per PR, so even at 10 PRs/day the cumulative active time per env is on the order of hours, not days.
- **Stored time dominates the env's life.** Open PRs sit hibernated between pushes; closed PRs trigger the teardown job. The stored rate is much lower than the active rate per hour.

The cost-shape lever is hibernate-between-pushes plus teardown-on-close. The headline alternative is one always-on shared "BC test server" billed at the active rate 24/7, with serialised tests and the inevitable shared-state corruption.

Current rates live on the [pricing page](https://bcdock.io/pricing).

## Next steps

- [`bcdock/setup-cli@v1`](https://github.com/bcdock/setup-cli) — when this action ships, replace the `curl … | sh` step with `uses:`
- [Authentication](../cli/auth.md) — scope details for the token
- [AL extension loop](al-extension-loop.md) — what each step in the workflow actually does
- [Exit codes](../cli/exit-codes.md) — what your CI should do on each failure mode
