---
title: bcdock auth signup
---

## bcdock auth signup

Activate your BCDock account using an invite code

### Synopsis

Activate your account after receiving an invite code via email.

If you don't have an invite code yet, join the waitlist first:
  bcdock auth join-waitlist

Once you have a code, run:
  bcdock auth signup --invite-code ABCD1234 --email you@example.com

The CLI looks up your waitlist entry via the invite code and pre-fills any
BC config you supplied at waitlist time. After activation, run:
  bcdock auth login --email you@example.com

to receive an OTP and complete login. The first BC environment is queued
automatically when activation succeeds (if a complete config is available).

Exit codes:
  0   ok
  1   general error (invalid invite code, email mismatch)
  4   rate-limited

```
bcdock auth signup [flags]
```

### Examples

```
  bcdock auth signup --invite-code ABCD1234 --email you@example.com
  bcdock auth signup --invite-code ABCD1234 --email you@example.com --bc-version 25.5 --country au
```

### Options

```
      --accept-eula            Accept the Microsoft NAV/BC on Docker EULA
      --accept-insider-eula    Accept the BC Insider EULA (preview versions)
      --artifact-type string   Artifact type: Sandbox or OnPrem
      --bc-version string      BC version (e.g. 27.5)
      --country string         BC country code (e.g. AU)
      --email string           Email address (the one your invite was issued for)
  -h, --help                   help for signup
      --invite-code string     Invite code from your waitlist invite email
      --multi-tenant string    true|false - multi-tenant container
      --name string            Display name (defaults to waitlist entry name if any)
      --region string          Azure region (e.g. australiaeast)
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

