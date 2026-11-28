---
title: bcdock al test
---

## bcdock al test

Run the test codeunits of a published test app on a BC env

### Synopsis

Run the test codeunits of a test app against a BCDock env and print a
pass/fail summary per codeunit. The app must already be published to the env
('bcdock env publish'); this command only runs its tests.

How it works:
  1. Reads the test codeunits (Subtype = Test) from the .app file itself.
  2. Gets Microsoft's AL tool (altool) for the env's BC version from NuGet
     (18.x for BC 28-29, 30.x for BC 30+), cached per version under
     ${BCDOCK_AL_CACHE:-$XDG_CACHE_HOME/bcdock}/altool. Never a global install.
  3. Reveals the env's credentials (audited) and passes them to altool in its
     environment, never on the command line.
  4. Runs 'altool runtests' against the env's dev endpoint.

Requirements:
  - The env runs BC 28 or later. Older envs cannot run tests remotely; the
    command refuses before doing anything.
  - A .NET 8 or later runtime (Microsoft.NETCore.App and
    Microsoft.AspNetCore.App), because altool runs on .NET. Check with
    'dotnet --list-runtimes'; install from https://dot.net.

--codeunit narrows the run to the named test codeunit ids (repeatable).
--company runs in that company instead of the env's default.
--junit writes JUnit XML: one testsuite per codeunit, one testcase per test.

Exit codes:
  0   every test ran and passed
  1   general error (bad flags, unreadable app, download failed)
  3   auth failure (missing or invalid token)
  5   environment not found
  6   tests ran and at least one failed
  7   tests could not run (BC version below 28, no .NET 8+, altool or the env failed)

```
bcdock al test <test.app> [flags]
```

### Examples

```
  bcdock env publish my-env build/MyTests_1.0.0.0.app
  bcdock al test build/MyTests_1.0.0.0.app --env my-env
  bcdock al test MyTests.app --env my-env --codeunit 50100 --junit results.xml
  bcdock al test MyTests.app --env my-env -o json
```

### Options

```
      --codeunit ints      Run only this test codeunit id (repeatable)
      --company string     Company to run the tests in (default: the env's default company)
      --env string         Env the test app is published to (required)
  -h, --help               help for test
      --junit string       Write JUnit XML results to this file
      --refresh            Re-download altool even if a cached copy exists
      --timeout duration   Maximum time for the test run (default 30m0s)
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

* [bcdock al](bcdock_al.md)	 - Compile AL projects and run their tests against a BC env

