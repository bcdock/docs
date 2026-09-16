---
title: bcdock env
---

## bcdock env

Manage Business Central environments

### Synopsis

Create, list, inspect, and delete BC environments.

Config discovery: BC versions with a pre-built VM image (~7-15 min provisioning
on a warm pool) are called "fast configs". Versions without one trigger a ~78
min image build on first use - usually not what you want. Always prefer fast
configs unless you explicitly need a specific version.

  bcdock artifacts list --region <r> --fast-only   # browse fast configs in a region
  bcdock env create                                 # interactive picker (fast configs only)

Exit codes:
  0   ok
  1   general error

### Examples

```
  bcdock env create --name my-env --version 25.5 --country au --region westus2 --wait
  bcdock env list -o json
  bcdock env get my-env
  bcdock env delete my-env --force
```

### Options

```
  -h, --help   help for env
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
* [bcdock env create](bcdock_env_create.md)	 - Create a new BC environment
* [bcdock env credentials](bcdock_env_credentials.md)	 - Reveal an environment's BC admin credentials
* [bcdock env delete](bcdock_env_delete.md)	 - Delete an environment
* [bcdock env download-symbols](bcdock_env_download-symbols.md)	 - Download AL symbol packages from a BC environment's dev endpoint
* [bcdock env get](bcdock_env_get.md)	 - Get details of an environment
* [bcdock env hibernate](bcdock_env_hibernate.md)	 - Hibernate an environment (saves to blob storage, frees pool slot)
* [bcdock env launch-json](bcdock_env_launch-json.md)	 - Emit a VS Code launch.json config for publishing to a BC environment
* [bcdock env list](bcdock_env_list.md)	 - List environments
* [bcdock env logs](bcdock_env_logs.md)	 - Show container logs (default) or provisioning log history
* [bcdock env open](bcdock_env_open.md)	 - Open the BC Web Client in a browser
* [bcdock env publish](bcdock_env_publish.md)	 - Publish (deploy) an AL .app to a BC environment
* [bcdock env query](bcdock_env_query.md)	 - Run a read-only OData query against a BC environment
* [bcdock env resume](bcdock_env_resume.md)	 - Resume a hibernated environment
* [bcdock env usage](bcdock_env_usage.md)	 - Show billing usage for an environment
* [bcdock env wait](bcdock_env_wait.md)	 - Block until an environment reaches one of the requested states

