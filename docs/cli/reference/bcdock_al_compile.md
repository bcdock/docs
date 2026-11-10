---
title: bcdock al compile
---

## bcdock al compile

Compile an AL project using the env-matched alc

### Synopsis

Download the env's bundled AL Language extension (cached), extract the
matching alc binary, and run it against the AL project.

Caching: the vsix is keyed by the env's platformVersion (falling back to
bcVersion when null) and stored under ${BCDOCK_AL_CACHE:-$XDG_CACHE_HOME/bcdock/al-vsix}.
Re-use across envs on the same BC platform is automatic. Use --refresh to
force re-download.

Args after a literal '--' are forwarded verbatim to alc, so anything alc
supports (e.g. /generatecode, /analyzer, /ruleset) goes through unmodified.

Exit codes:
  0   ok
  1   general error (compile failed, download failed, env not running)
  3   auth failure (missing or invalid token)
  5   environment not found

```
bcdock al compile [flags]
```

### Examples

```
  bcdock al compile --env my-env
  bcdock al compile --env my-env --out build/MyApp_1.0.0.0.app
  bcdock al compile --env my-env --refresh
  bcdock al compile --env my-env -- /generatecode+ /errorlog:build/diag.log
```

### Options

```
      --env string             Env whose BC platform's alc to use (required)
  -h, --help                   help for compile
      --insecure               Skip TLS verification for the downloads endpoint (self-signed certs)
      --out string             Output .app file passed as /out: (alc derives the default from app.json if empty)
      --package-cache string   Symbol cache directory passed as /packagecachepath: (default ".alpackages")
      --project string         AL project directory passed to alc as /project: (default ".")
      --refresh                Re-download the vsix even if the cached copy exists
      --timeout duration       vsix download timeout (default 5m0s)
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

* [bcdock al](bcdock_al.md)	 - Compile AL projects using the alc that matches the target BC env

