---
title: AL-Go for GitHub - build and test on BCDock, no Docker
description: Run an AL-Go for GitHub build on a GitHub-hosted Linux runner. Each build compiles against a fresh BCDock environment, publishes your apps, runs your tests there and deletes the environment. Setup, what to expect, and the limits.
schema_type: HowTo
---

# AL-Go for GitHub

Goal: your [AL-Go for GitHub](https://github.com/microsoft/AL-Go) per-tenant extension (PTE) repo builds on a GitHub-hosted `ubuntu-latest` runner, with no Docker and no Windows runner. Each build creates a fresh BCDock environment, compiles your apps with that environment's own compiler and symbols, publishes them, runs your test codeunits in it, and deletes it. Test results appear in AL-Go's own test summary, and a failing test turns the build red.

You add a set of AL-Go override scripts to your repo's `.AL-Go` folder. AL-Go calls them wherever it would otherwise use a local Docker container, so the rest of AL-Go works as usual.

## What to expect

- **About 7 to 8 minutes per build when a pool is ready**, measured on a small sample app with Business Central 28.5: creating the environment took 3.5 minutes, and compiling, publishing and running tests took about 1.5 minutes together. When no pool is ready, creating the environment takes longer, as for any new environment (about 15 minutes in our runs). Larger apps take longer to compile, publish and test.
- **No Business Central artifacts are downloaded to the runner.** Symbols and the compiler come from the environment.
- **Each build is billed like any BCDock environment**: the active time of its environment, per second, from create to delete. See [pricing](https://bcdock.io/pricing).
- **The environment is deleted on every path**: after a green build, after failing tests, and when a step fails before the tests (for example a compile error or an environment that does not start).
- **The build log marks each BCDock step** with a small BCDock banner: create env, compile, publish, run tests, delete env.

## Limits

- **Business Central 28 or later.** Running tests remotely needs the development API that Business Central 28 introduced, so the overrides refuse an earlier `artifact` setting.
- **Sandbox, per-tenant extensions.** This guide and the overrides are tested with AL-Go's PTE template and sandbox artifacts.
- **Code cops are not applied.** If your settings enable CodeCop, AppSourceCop, PerTenantExtensionCop or UICop, the build compiles without them and prints a warning.
- **Only Microsoft dependencies.** Dependencies published by Microsoft are already in the environment. Other dependencies (from NuGet feeds, GitHub Packages, `appDependencyProbingPaths` or AppSource) are not supported yet: the build stops and names the dependency.
- **Tested with AL-Go for GitHub v10.0.** The overrides set two values inside AL-Go's pipeline that AL-Go offers no setting for. A later AL-Go version may need updated overrides; this page will say when.

## Prerequisites

- An AL-Go for GitHub PTE repo, for example one created from Microsoft's [AL-Go-PTE](https://github.com/microsoft/AL-Go-PTE) template, with your app and test app folders.
- A BCDock API key with `env:read` and `env:write` scopes, from [app.bcdock.io/profile/api-keys](https://app.bcdock.io/profile/api-keys).
- Your BCDock company's default region set to where you want build environments (`bcdock companies set-location <country-code> --region <azure-region>`). Each build environment is created there. `bcdock me show` shows the current one in its `REGION` column.
- PowerShell 7 (`pwsh`) on your machine for the two setup scripts below.

## Setup

Run each step from the root of your repo, then commit and push.

### 1. Add the API key as a repo secret

In GitHub: **Settings > Secrets and variables > Actions > New repository secret**. Name it `BCDOCK_TOKEN` and paste the key.

### 2. Pass the secret to the build job

AL-Go only gives the build job the secrets named in its workflow. In `.github/workflows/CICD.yaml`, find the build job's `secrets:` line and add `BCDOCK_TOKEN,` at the start:

```yaml
      secrets: 'BCDOCK_TOKEN,licenseFileUrl,codeSignCertificateUrl,*codeSignCertificatePassword,keyVaultCertificateUrl,*keyVaultCertificatePassword,keyVaultClientId,gitHubPackagesContext,applicationInsightsConnectionString'
```

Do the same in `.github/workflows/PullRequestHandler.yaml` if pull requests should build too.

!!! warning "After an AL-Go update"
    AL-Go's **Update AL-Go System Files** workflow rewrites these workflow files from its template. Each time you take an update, check that `BCDOCK_TOKEN,` is still on the `secrets:` line, and add it again if not.

### 3. Add the BCDock override scripts

This downloads the scripts from this site into `.AL-Go`:

```powershell
$base  = 'https://docs.bcdock.io/al-go/overrides'
$files = '_bcdock.ps1', 'CompileAppInBcContainer.ps1', 'DockerPull.ps1', 'GetBcContainerAppInfo.ps1',
         'ImportTestToolkitToBcContainer.ps1', 'InstallMissingDependencies.ps1', 'NewBcContainer.ps1',
         'PipelineInitialize.ps1', 'PublishBcContainerApp.ps1', 'RemoveBcContainer.ps1',
         'RunTestsInBcContainer.ps1', 'bcdock/BCDock.AlGo.psm1'
foreach ($f in $files) {
    $target = Join-Path '.AL-Go' $f
    New-Item -ItemType Directory -Force (Split-Path $target) | Out-Null
    Invoke-WebRequest "$base/$f" -OutFile $target
}
```

The scripts are plain PowerShell. Read them before you commit them; each one starts with a comment saying what it replaces.

### 4. Settings

In `.AL-Go/settings.json`, point `artifact` at Business Central 28 or later, set `country` to the same country, and keep the compiler folder setting on:

```json
  "country": "au",
  "artifact": "bcartifacts/sandbox/28.5/au/latest",
  "useCompilerFolder": true
```

Use your own major.minor and country, from `bcdock artifacts list --region <your-region> --fast-only`, which lists what BCDock can create now. Give the version as major.minor (`28.5`), not a full build: BCDock then creates the newest build of 28.5 that it has ready, so the pipeline keeps working when a new build lands, while a pinned full build stops working once it is retired. Set `country` to the artifact's country: when the two differ, AL-Go swaps the artifact's version for the newest build of that release, which BCDock may not have yet. The compiler folder setting looks wrong for a build that downloads no compiler, but it is what stops AL-Go from downloading the artifacts just to check this setting; the overrides then compile against the environment instead.

In `.github/AL-Go-Settings.json`, run every job on Linux:

```json
  "runs-on": "ubuntu-latest",
  "shell": "pwsh",
  "githubRunner": "ubuntu-latest",
  "githubRunnerShell": "pwsh"
```

Then make the same change in the workflow files that are already there. This is the rewrite AL-Go's own update makes from these settings:

```powershell
Get-ChildItem .github/workflows/*.yaml | ForEach-Object {
    $text = Get-Content $_ -Raw
    $new = $text.Replace('runs-on: [ windows-latest ]', 'runs-on: [ ubuntu-latest ]').Replace('shell: powershell', 'shell: pwsh')
    if ($new -ne $text) { Set-Content $_ $new -NoNewline }
}
```

### 5. Run a build

Commit and push, then run **CI/CD** from the **Actions** tab (or push to `main`). In the **Build** job's log you see a BCDock banner as each step starts, then your test results, and the run's summary shows AL-Go's test table.

## When something fails

| You see | What it means |
|---|---|
| `BCDOCK_TOKEN is not set` | Step 1 or step 2 is missing; check the `secrets:` line after any AL-Go update. |
| `BC <version> is not supported` | The `artifact` setting is earlier than Business Central 28. |
| `No ready image matches BC <major.minor>` | BCDock has no ready build of that release in your region. The error lists the ones it has; use one of those in `artifact`. |
| `No BC artifact for <version>` | BCDock cannot create that version yet. Pick one from `bcdock artifacts list --region <your-region> --fast-only`, and check that `country` matches the artifact's country (see [step 4](#4-settings)). |
| `could not read your account with BCDOCK_TOKEN` | The key in the `BCDOCK_TOKEN` secret is wrong or revoked. Mint a new one and update the secret. |
| `no region for the build env` | Your company has no default region (`bcdock me show` shows an empty `REGION`). Set one with `bcdock companies set-location`. |
| `these dependencies are not in the env and cannot be installed by the BCDock overrides yet` | One of your apps depends on a non-Microsoft app. See [Limits](#limits). |
| `Run-AlPipeline has no useGenericImage here` (or `useCompilerFolder`) | Your AL-Go version changed how its pipeline works. Check this page for updated overrides. |
| A red build with `Function <test> <message>` annotations | Your tests ran and some failed; the annotation and the log show each failure and its AL call stack. |

The environment is still deleted in every case above. If a run is cancelled mid-build, its environment can be left behind, and it keeps billing until you delete it: `bcdock env list` shows it (its name starts with `algo-`), and `bcdock env delete <name>` removes it.

## Next steps

- [GitHub Actions](github-actions.md) - a fresh environment per pull request, outside AL-Go
- [AL extension loop](al-extension-loop.md) - the same compile and publish steps from your terminal
- [Limitations](../reference/limitations.md) - what BCDock environments support today
