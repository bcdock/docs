---
title: bcdock auth
---

## bcdock auth

Authenticate with the BCDock platform

### Synopsis

Manage authentication credentials.

BCDock access is currently invitation-only. New users follow this path:

  1. bcdock auth join-waitlist                                    (request access)
  2. Wait for your invite (reviewed within 48 hours)
  3. bcdock auth signup --invite-code CODE --email you@example.com (activate account)
  4. bcdock auth login --email you@example.com                    (OTP login)

Returning users:
  bcdock auth login --email you@example.com

For CI/CD or agent use, store an API key directly:
  bcdock auth set-token <key>

See 'bcdock help authentication' for detailed token-source precedence and
CI/CD best practices.

Exit codes:
  0   ok
  1   general error

### Examples

```
  bcdock auth login --email you@example.com
  bcdock auth whoami
  bcdock auth set-token bdk_xxxxxxxxxxxxxxxxxxxx
  bcdock auth logout
```

### Options

```
  -h, --help   help for auth
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
* [bcdock auth join-waitlist](bcdock_auth_join-waitlist.md)	 - Submit a waitlist entry to request access to BCDock
* [bcdock auth login](bcdock_auth_login.md)	 - Log in via email OTP (returning users; account must already exist)
* [bcdock auth logout](bcdock_auth_logout.md)	 - Clear stored credentials
* [bcdock auth set-token](bcdock_auth_set-token.md)	 - Store an API token persistently
* [bcdock auth signup](bcdock_auth_signup.md)	 - Activate your BCDock account using an invite code
* [bcdock auth whoami](bcdock_auth_whoami.md)	 - Show the currently authenticated user

