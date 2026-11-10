---
title: Anonymise-in-place
description: Why BCDock anonymises rather than cascade-deletes for GDPR Art. 17 / APP 11. The architectural rationale, the tradeoff, and the legitimate-interest retention.
---

# Anonymise-in-place

When you delete your BCDock account, we anonymise the account record in place rather than cascade-deleting it. This page is the architectural rationale; the customer-facing walkthrough lives at [guides/account-deletion](../guides/account-deletion.md), and the security-level mechanics at [security/account-deletion](../security/account-deletion.md).

## The choice

GDPR Article 17 (right to erasure) and Australian Privacy Principle 11 are satisfied by either deletion or anonymisation. Recital 26 of the GDPR makes anonymous data outside the regulation entirely - once the data is no longer about an identifiable person, the regulation doesn't reach it.

That gives us two mechanisms with the same legal outcome:

- **Hard-purge** - delete the account record and cascade-delete every record that referenced it
- **Anonymise-in-place** - overwrite the account record's personal data with placeholders, leave referenced records intact

We chose anonymise-in-place. The cascade approach has costs that anonymisation avoids.

## What hard-purge would destroy

| Class | Why deletion is harmful |
|---|---|
| **Audit trail** | Every meaningful API action references the acting user. Cascading the audit entries breaks "what happened" history; orphaning them breaks referential integrity. |
| **Financial records** | Subscription history and usage records reference users and companies. Deleting them after-the-fact would corrupt billing reconciliation and invoice records that may be legally required to retain. |
| **Provisioning logs** | Keyed by environment, but the environment record itself is owned by the user. Cascading them destroys the operational telemetry needed to debug platform issues months later. |
| **Multi-user companies** | Co-member companies have other active users. Hard-purging the deleting user's record could orphan ownership; we'd need a transfer-then-delete dance, executed atomically with the cascade. |

Anonymisation preserves the structure (references still resolve, audit records still link, financial records still tie to a row that says "deleted user") and removes the bytes that *were the person*.

## What anonymise-in-place does

For the deleting user's account at +30d (after the grace window):

- Personal contact and identity data (email, display name, OAuth subject, last login timestamp, time zone) is overwritten to null.
- A small set of non-identifying data is retained: the internal account identifier and creation timestamp, the auth-provider type, a salted hash of the original email (for legitimate-interest retention, see below), a trial-history flag, and an account status set to `deleted`.

For sole-owner companies, the same shape applies to the company record (name and slug are overwritten to generic placeholders).

For co-member companies, your membership is removed and ownership transfers to the next-oldest member if applicable; the company itself is untouched.

## What's actually deleted

Two classes of data are real-deleted at +30d, not anonymised:

- **Hibernation backup blobs** - your BC database snapshots. These *are* personal data (or contain it), so they go.
- **Session and OTP state** - ephemeral, wiped at anonymisation regardless.

## What's untouched

- **Provisioning logs** - keyed by environment / pool ID, with no user identifier. Operational telemetry.
- **Pool / VM / image records** - platform infrastructure, doesn't reference users.

## The trade-off

Anonymise-in-place isn't free. Two costs:

### Cost 1 - retaining a salted email hash

We keep a salted hash of the original email after anonymisation (SHA-256 of the lowercased email plus a server-side salt, hex-encoded). Without it, two things stop working:

- **Re-registration restore** - when an anonymised user signs up again with the same email, we restore their account in place. Possible only because the hash matches an existing record.
- **Trial-abuse suppression** - the trial-history flag carries forward across re-registration. Without the hash, "one trial per human" is unenforceable.

The legal basis for retention is GDPR Art. 17(3)(e) and APP 11.2(c) - defending against repeated-signup trial-abuse is a legitimate-interest grounds. The salt lives in Azure Key Vault; it never appears in the database, never appears in code or logs, and never rotates (rotating would invalidate every hash and lose the suppression check). A salt compromise is the same threat model as a password-hash leak.

The security view is documented in [security/account-deletion](../security/account-deletion.md).

### Cost 2 - anonymised rows look like rows

A row whose personal fields are null doesn't *feel* like your rights have been satisfied. It feels like a stale row.

Mitigations: the account's `deleted` status excludes it from customer-facing APIs by default. Internal queries that need to see it are explicit about it. The privacy policy says it explicitly: "we anonymise rather than purge; here's what's left, here's why."

## What we considered and didn't choose

- **Hard-delete with cascade** - destroys audit trails, see above.
- **Hard-delete with FK = NULL** - leaves records pointing at NULL, which breaks invariants in many places.
- **Tombstone tables** - copy the user's important records into a separate "deleted users" table before purging the original. Doubles complexity without clear gain over in-place anonymisation.
- **Encryption-at-rest with per-user keys, then key-destroy on delete** ("crypto-shredding") - clean in theory; fails in practice because backups, replicas, and offsite storage all carry encrypted bytes that an attacker with the key can recover. The key-destroy promise becomes "we destroyed all known copies of the key," which is hard to defend.

In-place anonymisation has the best ratio of "actually destroys identifiability" to "preserves operational integrity."

## Re-registration

If a previously-anonymised email signs up again, the sign-in step computes the salted hash and finds the matching anonymised account. We restore the account in place (plaintext email re-attached, hash cleared, status active, display name reset) - equivalent to a fresh signup but reusing the original account identifier, audit history, and relations.

The original company is **not** restored; it stays anonymised. You create a fresh company. If the restored account had previously consumed a trial, the new company doesn't get a free trial - it goes straight to a paid plan.

The full flow is documented at [security/account-deletion](../security/account-deletion.md).

## Threat model

- **Adversarial deletion** - `bcdock me delete --confirm <email>` requires the email exactly. Portal requires typing it. No zero-click path.
- **Anonymisation reversal** - once anonymisation runs, the original email is unrecoverable from our side. Restoration requires you to control the inbox.
- **Salt compromise** - would expose the hash to rainbow-table attack on common emails. Mitigations: Key Vault RBAC, no rotation (single point of leak), separate salt per environment in principle.
- **Email recycling** - Gmail recycles abandoned addresses; a new human acquiring an old email is treated as the original owner. Same threat model as password-reset-via-email everywhere.

## Read more

- [Guides → Account deletion](../guides/account-deletion.md) - customer walkthrough
- [Security → Account deletion](../security/account-deletion.md) - security-level mechanics
- [Security → Data handling](../security/data-handling.md) - the data classes this applies to
