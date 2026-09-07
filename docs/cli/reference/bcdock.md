---
title: bcdock
---

## bcdock

BCDock CLI - manage Business Central environments

### Synopsis

Welcome to BC[)OCK! Managed Business Central sandboxes in cloud.

BCDock CLI wraps the BCDock Platform API for use in terminals,
scripts, and AI agent workflows.

Set BCDOCK_TOKEN to authenticate without --token.  (env: BCDOCK_TOKEN)
Set BCDOCK_API_URL to target a different API endpoint.  (env: BCDOCK_API_URL)

See 'bcdock help authentication' for token-source precedence and CI/CD guidance.
See 'bcdock help agent-workflows' for recipes for Claude, Copilot, and similar.

### Examples

```
  bcdock env list
  bcdock env create --name my-env --version 25.5 --country au --region westus2 --wait
  bcdock auth whoami
```

### Options

```
      --api-url string     API base URL (env: BCDOCK_API_URL)
  -h, --help               help for bcdock
      --no-color           Disable colored output
  -o, --output string      Output format: table, json, csv (default "table")
  -q, --quiet              Suppress non-essential output
      --timeout duration   Request timeout (default 30s)
      --token string       API token (env: BCDOCK_TOKEN)
```

### SEE ALSO

* [bcdock al](bcdock_al.md)	 - Compile AL projects using the alc that matches the target BC env
* [bcdock artifacts](bcdock_artifacts.md)	 - Discover BC artifact versions and countries
* [bcdock auth](bcdock_auth.md)	 - Authenticate with the BCDock platform
* [bcdock companies](bcdock_companies.md)	 - Manage companies (billing entities)
* [bcdock completion](bcdock_completion.md)	 - Generate the autocompletion script for the specified shell
* [bcdock config](bcdock_config.md)	 - Discover available regions and configurations
* [bcdock env](bcdock_env.md)	 - Manage Business Central environments
* [bcdock me](bcdock_me.md)	 - Manage your own account (export data, request deletion, cancel)
* [bcdock usage](bcdock_usage.md)	 - Show company-level usage and billing
* [bcdock version](bcdock_version.md)	 - Print the bcdock CLI version
* [bcdock waitlist](bcdock_waitlist.md)	 - Join the BCDock waitlist

