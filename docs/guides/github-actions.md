---
title: GitHub Actions - ephemeral BC environments per pull request
description: Spin up a fresh BC environment on PR open, compile and publish your extension into it, and tear down on close. Complete workflow template, plus where AL test runs stand today.
schema_type: HowTo
---

# GitHub Actions

Goal: every PR gets a fresh BC environment, the extension built from the PR branch is compiled against it and published into it, and it tears down when the PR closes. Provisioning the env is the long step (about 15 minutes); compile and publish run in the minutes after. Running your AL tests in this pipeline is not supported yet; if you use AL-Go for GitHub, [AL-Go for GitHub](al-go.md) runs them in a BCDock environment. See [Running your AL tests](#running-your-al-tests).

## Prerequisites

- A `BCDOCK_TOKEN` in your repo's GitHub secrets (`Settings → Secrets and variables → Actions → New repository secret`). Mint from `app.bcdock.io/profile/api-keys` with `env:read` + `env:write` scopes.
- A `bcdock.yaml` at the repo root (optional but recommended) so flag defaults don't have to repeat across jobs.
- Nothing to install by hand: the [`bcdock/setup-bcdock`](https://github.com/bcdock/setup-bcdock) action installs the CLI and authenticates it in one step. To do it yourself instead, see [Without the action](#without-the-action).

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

# The PR comment step posts with the job's GITHUB_TOKEN.
permissions:
  contents: read
  pull-requests: write

# Every run: step below is PowerShell 7 (pwsh is installed on GitHub's Linux, Windows and macOS runners).
defaults:
  run:
    shell: pwsh

env:
  ENV_NAME: pr-${{ github.event.pull_request.number }}
  # A major.minor: BCDock creates the newest build of 28.5 with a ready image in your region.
  # A full version pins one build, but retired builds stop working; major.minor keeps up.
  BC_VERSION: "28.5"

jobs:
  provision-and-publish:
    if: github.event.action != 'closed'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      # Installs the CLI and authenticates it for the rest of the job.
      - uses: bcdock/setup-bcdock@v1
        with:
          token: ${{ secrets.BCDOCK_TOKEN }}

      - name: Create or resume environment
        run: |
          bcdock env get $env:ENV_NAME -o json *> $null
          if ($LASTEXITCODE -eq 0) {
            # The PR already has an environment: make sure it is running.
            # A resume that fails does not fail the step (for example, when the environment
            # is already running).
            bcdock env resume $env:ENV_NAME --wait --wait-timeout 30m
            exit 0
          }
          bcdock env create --name $env:ENV_NAME --version $env:BC_VERSION --country au `
            --region australiaeast --wait --wait-timeout 30m

      - name: Pull AL symbols
        run: bcdock env download-symbols $env:ENV_NAME --out-dir .alpackages

      - name: Compile extension
        run: bcdock al compile --env $env:ENV_NAME --out build/MyExtension.app

      - name: Publish into BC
        run: bcdock env publish $env:ENV_NAME build/MyExtension.app

      - name: Comment env URL on PR
        env:
          GH_TOKEN: ${{ github.token }}
        run: |
          $bc = bcdock env get $env:ENV_NAME -o json | ConvertFrom-Json
          $body = "BC environment ready: $($bc.webClientUrl)`n`nSign-in credentials: run ``bcdock env credentials $($bc.name)``"
          gh pr comment ${{ github.event.pull_request.number }} --repo $env:GITHUB_REPOSITORY --body $body

      - name: Hibernate when done (drops billing to the stored rate)
        if: always()
        run: |
          bcdock env hibernate $env:ENV_NAME --wait
          # A failed hibernate is a billing concern, not a build result: never fail the job on it.
          exit 0

  teardown:
    if: github.event.action == 'closed'
    runs-on: ubuntu-latest
    steps:
      - uses: bcdock/setup-bcdock@v1
        with:
          token: ${{ secrets.BCDOCK_TOKEN }}

      - name: Delete environment
        # Exit 5 means there was no environment to delete (for example, the PR closed before
        # one was created). Deleting one that was already deleted succeeds too. Any other
        # failure fails the job, so an environment is never left running unnoticed. Needs
        # bcdock 0.4.2 or later.
        run: |
          bcdock env delete $env:ENV_NAME --force --wait
          if ($LASTEXITCODE -eq 5) { exit 0 }
          exit $LASTEXITCODE
```

## Running your AL tests

Running AL tests from this workflow is **not supported yet**. Your test app publishes; running it is what is missing:

- **Publishing a test app works.** A test app that depends on BC's test libraries (for example Library Assert) publishes into a BCDock environment with `bcdock env publish`. We have checked this on a Business Central 28 sandbox environment.
- **BCDock has no command that runs tests.** This workflow calls the `bcdock` CLI directly, and the CLI has no test verb yet.

What you can do today:

- **If you use AL-Go for GitHub**, follow [AL-Go for GitHub](al-go.md): each AL-Go build creates a BCDock environment, runs your test codeunits in it and shows the results in AL-Go's test summary, on a Linux runner with no Docker.
- Otherwise, keep running your AL tests where you run them now, and use this workflow for the part it covers: a fresh, isolated environment per PR with your extension compiled against it and published into it, ready for a reviewer to open.
- Use the environment for manual testing: the PR comment carries its URL, and `bcdock env credentials` gives the sign-in.

A native `bcdock env test` command is planned.

## One environment for one run

When a job needs a fresh environment and nothing more, let the action create it. It waits until the environment is running and gives you its id and URL as outputs:

```yaml
- uses: bcdock/setup-bcdock@v1
  id: bcdock
  with:
    token: ${{ secrets.BCDOCK_TOKEN }}
    create: true
    name: run-${{ github.run_id }}
    bc-version: "28.5"  # the newest ready build of BC 28.5
    country: au

- shell: pwsh
  run: "BC is at ${{ steps.bcdock.outputs.env-url }}"

# ... publish, test ...

- name: Delete environment
  if: always()
  shell: pwsh
  run: bcdock env delete "run-${{ github.run_id }}" --force --wait
```

The action never deletes what it creates, so the delete step is yours. Delete by the name you chose: that also cleans up after a create that failed part way.

## Without the action

The action is a convenience over two steps you can write yourself: install the CLI, and set `BCDOCK_TOKEN` for every step that calls it.

```yaml
env:
  BCDOCK_TOKEN: ${{ secrets.BCDOCK_TOKEN }}

steps:
  - name: Install bcdock
    shell: pwsh
    run: Invoke-RestMethod https://cli.bcdock.io/install.sh | sh
```

The install script covers Linux and macOS runners. On a Windows runner, use the action, or the Windows script. It installs to your user folder, so add that folder to `GITHUB_PATH` for the steps after it:

```yaml
  - name: Install bcdock (Windows runner)
    shell: pwsh
    run: |
      Invoke-RestMethod https://cli.bcdock.io/install.ps1 | Invoke-Expression
      Add-Content $env:GITHUB_PATH "$env:LOCALAPPDATA\Programs\bcdock"
```

## Patterns worth knowing

### Hibernate, don't delete, between pushes

A PR with 10 pushes to the same branch = 10 workflow runs. If each run creates a fresh env, you pay ~10 active provisions + 10 deletions. Hibernating between runs and resuming on the next push:

- Same active runtime per run (the env is running while your pipeline uses it)
- Between runs, the env sits at the much-lower stored rate
- Resuming a hibernated env usually takes about 4 minutes, against about 15 for a create. If no server with room is running in your region, one has to start first, and the resume takes about 10 to 15 minutes. Size your wait for that case: the template's `--wait-timeout 30m` covers it, and a job `timeout-minutes` should leave at least 20 minutes for the resume step.

The template above does this: it resumes when `bcdock env get` finds the environment, and creates it when it does not.

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
  shell: pwsh
  run: |
    bcdock env hibernate $env:ENV_NAME --wait
    exit 0
```

The `exit 0` after the command ends the step green whatever `bcdock` returned. A failed hibernate (env already in `error` state, etc.) shouldn't mark the job red - that's a billing concern, not a build result. The `if: always()` guarantees the step runs even when an earlier step failed.

### Per-PR teardown on close

The `teardown` job triggers on `closed` (whether merged or abandoned). If a PR sits closed without teardown, you keep paying the stored rate until manually cleaned up - the autoscaler doesn't garbage-collect customer envs.

For very long-lived PRs (multi-week WIP branches), you might want **scheduled hibernate**:

```yaml
on:
  schedule:
    - cron: '0 18 * * *'  # 6pm UTC daily
```

## Secret hygiene

- **Never** print `BCDOCK_TOKEN` to logs. GitHub auto-masks anything matching `secrets.*`, but a debug trace or an accidental print of a variable built from it defeats that.
- **Scope the token narrowly** - `env:write` is enough for the standard loop; don't add scopes the workflow doesn't actually use.
- **Rotate** when contributors leave. The portal's API keys page lets you revoke a single key without touching others.
- **One token per repo**, not one per CI vendor. Reduces blast radius and makes audit log entries easy to attribute.

## Cost shape

For a busy team running per-PR environments, the typical workload looks like:

- **Active runtime is short.** ~5 min per push, ~3 pushes per PR, so even at 10 PRs/day the cumulative active time per env is on the order of hours, not days.
- **Stored time dominates the env's life.** Open PRs sit hibernated between pushes; closed PRs trigger the teardown job. The stored rate is much lower than the active rate per hour.

The cost-shape lever is hibernate-between-pushes plus teardown-on-close. The headline alternative is one always-on shared "BC test server" billed at the active rate 24/7, with serialised tests and the inevitable shared-state corruption.

Current rates live on the [pricing page](https://bcdock.io/pricing).

## Next steps

- [`bcdock/setup-bcdock`](https://github.com/bcdock/setup-bcdock) - the action's inputs and outputs
- [Authentication](../cli/auth.md) - scope details for the token
- [AL extension loop](al-extension-loop.md) - what each step in the workflow actually does
- [Exit codes](../cli/exit-codes.md) - what your CI should do on each failure mode
