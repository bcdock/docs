---
title: bcdock waitlist join
---

## bcdock waitlist join

Submit a waitlist entry non-interactively (CI-friendly)

### Synopsis

Submit a waitlist entry without any prompts.

--name and --email are required; everything else is optional. Unlike
'bcdock auth join-waitlist' (interactive), this verb never prompts - it is the
form the smoke suite and other automation drive.

On the dev mirror with BCDOCK_DEV_TURNSTILE_BYPASS set, the submit clears the
Turnstile gate inline; otherwise it requests the deferred browser-confirm flow
and prints a confirm URL.

Exit codes:
  0   ok
  1   general error (missing required flag, validation)
  4   rate-limited

```
bcdock waitlist join [flags]
```

### Examples

```
  bcdock waitlist join --name "Jane Smith" --email jane@example.com
  bcdock waitlist join --name CI --email "ci+TOKEN.noemail@example.com"
```

### Options

```
      --artifact-type string   Default artifact type: Sandbox or OnPrem (optional)
      --bc-version string      Default BC version (optional)
      --country string         Default BC country code (optional)
      --email string           Email address (required)
  -h, --help                   help for join
      --multi-tenant string    true|false - preferred multi-tenant default (optional)
      --name string            Your name (required)
      --region string          Preferred Azure region (optional)
      --use-case string        What you'd like BCDock to help you with (optional)
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

* [bcdock waitlist](bcdock_waitlist.md)	 - Join the BCDock waitlist

