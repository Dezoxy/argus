# 7. Keep attachments in Backblaze B2, transferred directly by the browser

Date: 2026-09-20

## Status

Accepted

## Context

Attachments are large and the VM's disk is small. Storing them on the VM would
consume the same disk PostgreSQL lives on, and proxying every upload and
download through the API would spend the VM's bandwidth and memory on bytes the
API is not allowed to understand anyway.

Because attachments are encrypted on the client before upload, the store never
holds anything meaningful. That makes a third-party object store acceptable in a
way it would not be for a system that stored plaintext.

## Decision drivers

- [C-05](../requirements/constraints.md) — running costs must stay proportionate.
- [C-06](../requirements/constraints.md) — personal data stays in the EU.
- [QA-05](../requirements/quality-attributes.md) — an attachment must be
  unreadable to the storage provider.

## Considered options

1. Store attachment blobs on the VM disk.
2. Store them in the cloud provider's own object storage.
3. Store them in Backblaze B2 and have browsers transfer them directly against
   presigned URLs.

## Decision

We will keep attachment blobs in Backblaze B2 (`eu-central-003`). The API mints
presigned S3 URLs and never proxies the bytes: the browser uploads and downloads
ciphertext directly. Database backups go to a **separate, private** B2 bucket
under Object Lock.

## Consequences

Positive:

- Large transfers never touch the VM's CPU, memory or bandwidth.
- The store holds ciphertext only, so trusting the provider is unnecessary.
- B2's egress pricing keeps this affordable, and an EU bucket matches the
  residency commitment.

Negative / accepted trade-offs:

- The browser must reach a second origin, so the Content-Security-Policy pins
  that exact bucket hostname. The CSP and the bucket name must be changed
  together, and a deploy-time check fails closed if they disagree.
- Bucket CORS is configuration that lives with the provider, not in this
  repository.
- Lifecycle and retention are the bucket's behaviour rather than the
  application's, which means correctness depends on settings applied by hand
  and verified by runbook.

## Risks

- [RISK-006](../risks/architecture-risks.md) — provider-side configuration
  (CORS, lifecycle, Object Lock) is not in version control.

## Related

- Requirements: [C-06](../requirements/constraints.md),
  [QA-05](../requirements/quality-attributes.md)
- Architecture views: Containers, Maintenance
- Other ADRs: [1. Keep the server crypto-blind](0001-keep-the-server-crypto-blind.md)
