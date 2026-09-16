---
title: bcdock auth join-waitlist
---

## bcdock auth join-waitlist

Submit a waitlist entry to request access to BCDock

### Synopsis

Join the BCDock waitlist with optional default environment configuration.

BCDock is currently in early access - we onboard users carefully so we can
get the experience right. After you submit, an admin reviews your entry and
emails you an invite code (typically within 48 hours). Once you have the
code, run:

  bcdock auth signup --invite-code CODE --email you@example.com

Order of prompts (skip any with --flag or by pressing enter on optional ones):
  1. Default BC config - version, country, artifact type, region (all optional)
  2. What you'd like BCDock to help you with (optional)
  3. Your name (required)
  4. Your email (required)

Exit codes:
  0   ok
  1   general error
  4   rate-limited

```
bcdock auth join-waitlist [flags]
```

### Examples

```
  bcdock auth join-waitlist
  bcdock auth join-waitlist --name "Jane Smith" --email jane@example.com
  bcdock auth join-waitlist --name "Jane Smith" --email jane@example.com --bc-version 25.5 --country au --region australiaeast
```

### Options

```
      --artifact-type string   Default artifact type: Sandbox or OnPrem
      --bc-version string      Default BC version (optional)
      --country string         Default BC country code (optional)
      --email string           Email address (skips prompt)
      --expectations string    What you'd like BCDock to help you with (optional)
  -h, --help                   help for join-waitlist
      --multi-tenant string    true|false - preferred multi-tenant default
      --name string            Your name (skips prompt)
      --region string          Preferred Azure region (optional)
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

* [bcdock auth](bcdock_auth.md)	 - Authenticate with the BCDock platform

