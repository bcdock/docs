---
title: bcdock completion bash
---

## bcdock completion bash

Generate the autocompletion script for bash

### Synopsis

Generate the autocompletion script for the bash shell.

This script depends on the 'bash-completion' package.
If it is not installed already, you can install it via your OS's package manager.

To load completions in your current shell session:

	source <(bcdock completion bash)

To load completions for every new session, execute once:

#### Linux:

	bcdock completion bash > /etc/bash_completion.d/bcdock

#### macOS:

	bcdock completion bash > $(brew --prefix)/etc/bash_completion.d/bcdock

You will need to start a new shell for this setup to take effect.


```
bcdock completion bash
```

### Options

```
  -h, --help              help for bash
      --no-descriptions   disable completion descriptions
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

* [bcdock completion](bcdock_completion.md)	 - Generate the autocompletion script for the specified shell

