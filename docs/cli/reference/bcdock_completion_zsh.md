---
title: bcdock completion zsh
---

## bcdock completion zsh

Generate the autocompletion script for zsh

### Synopsis

Generate the autocompletion script for the zsh shell.

If shell completion is not already enabled in your environment you will need
to enable it.  You can execute the following once:

	echo "autoload -U compinit; compinit" >> ~/.zshrc

To load completions in your current shell session:

	source <(bcdock completion zsh)

To load completions for every new session, execute once:

#### Linux:

	bcdock completion zsh > "${fpath[1]}/_bcdock"

#### macOS:

	bcdock completion zsh > $(brew --prefix)/share/zsh/site-functions/_bcdock

You will need to start a new shell for this setup to take effect.


```
bcdock completion zsh [flags]
```

### Options

```
  -h, --help              help for zsh
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

