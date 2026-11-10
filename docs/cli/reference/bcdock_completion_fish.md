---
title: bcdock completion fish
---

## bcdock completion fish

Generate the autocompletion script for fish

### Synopsis

Generate the autocompletion script for the fish shell.

To load completions in your current shell session:

	bcdock completion fish | source

To load completions for every new session, execute once:

	bcdock completion fish > ~/.config/fish/completions/bcdock.fish

You will need to start a new shell for this setup to take effect.


```
bcdock completion fish [flags]
```

### Options

```
  -h, --help              help for fish
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

