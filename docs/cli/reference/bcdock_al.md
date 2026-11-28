---
title: bcdock al
---

## bcdock al

Compile AL projects and run their tests against a BC env

### Synopsis

Run alc.exe versioned to a specific BC environment, by extracting the
ALLanguage.vsix that BcContainerHelper bundled with that env's BC platform.

The vsix is served anonymously by every BC container on its downloads endpoint
(env.downloadsUrl/ALLanguage.vsix) - same binary BcContainerHelper unpacks
during container setup, so it's always version-matched to the env's platform.

'al test' runs a published test app's test codeunits on the env (BC 28+,
needs a .NET 8+ runtime for Microsoft's altool).

Exit codes:
  0   ok
  1   general error

### Examples

```
  bcdock al compile --env my-env
  bcdock al test build/MyTests_1.0.0.0.app --env my-env
```

### Options

```
  -h, --help   help for al
```

### Options inherited from parent commands

```
      --api-url string     API base URL (env: BCDOCK_API_URL)
      --no-color           Disable colored output
  -o, --output string      Output format: table, json, csv (default "table")
  -q, --quiet              Suppress non-essential output
      --timeout duration   Request timeout (default 30s)
      --token string       API token (env: BCDOCK_TOKEN)
```

### SEE ALSO

* [bcdock](bcdock.md)	 - BCDock CLI - manage Business Central environments
* [bcdock al compile](bcdock_al_compile.md)	 - Compile an AL project using the env-matched alc
* [bcdock al test](bcdock_al_test.md)	 - Run the test codeunits of a published test app on a BC env

