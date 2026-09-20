# 2. Use MLS through the ts-mls library

Date: 2026-09-20

## Status

Accepted

## Context

Given a crypto-blind server, the client needs a group key-agreement protocol
that gives forward secrecy and post-compromise security, supports groups larger
than two, and handles members joining and leaving with multiple devices each.

Writing that is not an option: the repository forbids hand-rolled cryptography
outright. The realistic choices were the Signal protocol's group mode and MLS
(RFC 9420), and for MLS in TypeScript the implementations were few and young.

## Decision drivers

- [C-02](../requirements/constraints.md) — no hand-rolled cryptography; all
  primitives come from a reviewed library.
- [C-03](../requirements/constraints.md) — all application code is TypeScript,
  and the same crypto code must run in the browser.
- [QA-02](../requirements/quality-attributes.md) — removing a member or a device
  must stop them reading later messages.

## Considered options

1. Signal protocol with sender keys for groups.
2. MLS (RFC 9420) through a WASM binding to a Rust implementation.
3. MLS (RFC 9420) through `ts-mls`, a TypeScript implementation.

## Decision

We will use MLS through `ts-mls`, wrapped in `packages/crypto` so that no other
package touches a primitive directly. The wrapper is the only place group state,
device keys and safety numbers are handled.

The choice was settled by a spike rather than on paper; the comparison and its
result are in
[mls-library-selection.md](../mls-library-selection.md).

## Consequences

Positive:

- Group membership changes, including multi-device, are the protocol's job
  rather than ours.
- A single wrapper package is a small, reviewable surface, and the crypto
  reviewer has one place to look.
- No WASM toolchain in the browser build.

Negative / accepted trade-offs:

- `ts-mls` is young and has a small ecosystem. We carry the risk of depending on
  it, and an interoperability or maintenance problem would be expensive.
- A pure-TypeScript implementation is slower than a Rust core compiled to WASM.
  Measured against this workload it is acceptable; at much larger groups it may
  not be.

## Risks

- [RISK-002](../risks/architecture-risks.md) — dependence on a young
  cryptographic library.

## Related

- Requirements: [C-02](../requirements/constraints.md),
  [QA-02](../requirements/quality-attributes.md)
- Architecture views: MessageFlow
- Other ADRs: [1. Keep the server crypto-blind](0001-keep-the-server-crypto-blind.md)
