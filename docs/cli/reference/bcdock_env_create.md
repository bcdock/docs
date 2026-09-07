---
title: bcdock env create
---

## bcdock env create

Create a new BC environment

### Synopsis

Create a new BC environment.

When --version / --country / --region are all omitted and stdin is a terminal,
the CLI fetches fast configs (versions with pre-built VM images) across all
regions and prompts you to pick one - avoiding the ~78 min image build that
happens when no pre-built image exists.

Pass the flags explicitly to skip the picker (scripts, CI, agent use).

Exit codes:
  0   ok
  1   general error
  3   auth failure (missing or invalid token)
  4   rate-limited
  10  provisioning failed (only with --wait and env status=failed)

```
bcdock env create [flags]
```

### Examples

```
  bcdock env create
  bcdock env create --name my-env --version 25.5 --country au --region westus2
  bcdock env create --name my-env --version 25.5 --country au --region westus2 --wait
```

### Options

```
      --country string          Country localisation (e.g. au, us, gb)
  -h, --help                    help for create
      --insecure                Skip TLS verification when publishing manifest apps to the dev endpoint
      --manifest string         Path to a bcdock.manifest.yaml. Implies --wait, because apps need a running environment. Precedence: an explicitly passed flag beats the manifest, which beats the built-in default
      --multi-tenant            Multi-tenant mode (default true)
      --name string             Environment name
      --region string           Azure region
      --type string             Environment type: sandbox or onprem (default "sandbox")
      --version string          BC version (e.g. 25.5)
      --wait                    Block until running or failed
      --wait-timeout duration   Max time to wait (default: 30m)
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

* [bcdock env](bcdock_env.md)	 - Manage Business Central environments

