# argus VoIP — Implementation Plan

> **Status: V1 SHIPPED (audio-only).** The plan was approved and built — `apps/api/src/calls/`,
> `apps/web/src/features/calls/`, `infra/stack/coturn/`, and the TURN ingress rules in both Terraform
> stacks. Delivered across the P0 (threat model + TURN infra) and P1 (gateway signaling, WebRTC peer
> wrapper, call UI) slices; see PRs #450–#453. Consilium-reviewed — [CONSILIUM.md](./CONSILIUM.md).
>
> **What actually shipped vs. what is written below:** V1 is **audio-only** and media is **always relayed**
> — the per-user relay-only preference is stored and readable but deliberately ignored until V1.1, so no
> user can leak their IP by opting out. **Video** and honouring the opt-out are both V1.1. Calls persist
> **nothing**: there is no call table, no participants, no timestamps, no duration. These files remain the
> design record; for the shipped shape see
> [`../../architecture/secure_messaging_platform_plan.md`](../../architecture/secure_messaging_platform_plan.md) §9.

The doc set behind **voice and video calling** in argus, the privacy-first, end-to-end-encrypted messenger PWA. The goal was 1:1 E2EE calls faithful to the six security invariants — the server relays encrypted media only and never sees plaintext or peer IPs. It maps each decision to PR-sized slices; those slices were built as **V1 (audio)**, so read this as the design rationale behind shipped code, not as pending work.

## Locked decisions

These are settled inputs to the plan, not open for relitigation. Everything below must conform to them.

| Area | Decision | Why it constrains the plan |
| --- | --- | --- |
| **V1 scope** | 1:1 only — **no group calls** (group is a future phase). Your target was audio + video; the consilium re-cut **shippable V1 to audio-only**, with video moving to **V1.1** — see [00](./00-overview-and-goals.md) & [08](./08-roadmap-and-delivery-slices.md) | Lets us use raw WebRTC P2P; no SFU to build or operate yet |
| **Media topology** | Fully self-hosted: WebRTC **P2P** for 1:1 media + a self-hosted **coturn** TURN relay. SFU is future-only | No third-party media servers; coturn relays ciphertext only |
| **IP privacy** | All media forced through TURN so peers never learn each other's IP. _(Shipped stricter than planned: V1 is **always** relay — the per-user opt-into-direct-P2P setting is stored but ignored until V1.1)_ | ICE candidate policy and TURN sizing are driven by a relay-only default |
| **Platform** | **PWA only** today (React + Vite). Native wrappers (Capacitor) are future-only | No CallKit/ConnectionService; background ring + push wake are constrained — the plan must be honest about this |

## Read in this order

1. [00-overview-and-goals.md](./00-overview-and-goals.md) — Overview & Goals: what V1 delivers, non-goals, and success criteria.
2. [01-architecture-and-crypto-model.md](./01-architecture-and-crypto-model.md) — Architecture & E2EE Crypto Model: how DTLS-SRTP media E2EE sits next to MLS, and how the server stays crypto-blind.
3. [02-signaling-protocol-and-state-machine.md](./02-signaling-protocol-and-state-machine.md) — Signaling Protocol & Call State Machine: the offer/answer/ICE message flow over the WebSocket gateway and the call lifecycle.
4. [03-infrastructure-turn-and-networking.md](./03-infrastructure-turn-and-networking.md) — Infrastructure: TURN/coturn & Networking: how coturn is exposed given Cloudflare Tunnel cannot carry UDP — the central ingress decision.
5. [04-server-api-and-database.md](./04-server-api-and-database.md) — Server API & Database: NestJS endpoints, TURN credential minting, and the proposed call-metadata tables. _(The endpoints and credential minting shipped; the **call-metadata tables did not** — V1 persists nothing about a call.)_
6. [05-frontend-pwa-and-webrtc.md](./05-frontend-pwa-and-webrtc.md) — Frontend, PWA & WebRTC Client: the call UI, `RTCPeerConnection` wiring, and honest PWA notification/wake limits with mitigations.
7. [06-threat-model-and-privacy.md](./06-threat-model-and-privacy.md) — Threat Model & Privacy: attacker model, IP-privacy guarantees, metadata exposure, and verification against the six invariants.
8. [07-comparative-survey.md](./07-comparative-survey.md) — Comparative Survey of E2EE Calling: how Signal, WhatsApp, Matrix/Element, Jitsi, and others solve the same problems, and what we borrow.
9. [08-roadmap-and-delivery-slices.md](./08-roadmap-and-delivery-slices.md) — Roadmap & Delivery Slices: the phased, PR-sized build order from signaling skeleton to shippable 1:1 calls.
10. [09-decision-log-and-open-questions.md](./09-decision-log-and-open-questions.md) — Decision Log & Open Questions: the record of what was decided, alternatives rejected, and what still needs an answer.

Review of record: **[CONSILIUM.md](./CONSILIUM.md)** — the 5-agent consilium review (scores, must-fixes, verdict). Read it to see where the plan was challenged and what changed.

## Status

**V1 shipped (audio-only).** `apps/api/src/calls/` (controller, authz, schemas, TURN credential minting),
`apps/web/src/features/calls/` (`useCall` state machine, `CallOverlay`), `apps/web/src/lib/`
(`peer-connection`, `call-signaling`, `turn-credentials`), `infra/stack/coturn/`, and TURN ingress rules in
both the Azure and AWS Terraform stacks. The `CallSignal` contracts live in `@argus/contracts`.

**Not shipped:** video (V1.1), group calls, and honouring the direct-P2P opt-out — V1 forces relay
unconditionally. **Nothing about a call is persisted**: no call table, no participants, no timestamps.

Both open risks below were resolved in the build: TURN ingress became a deliberate, documented NSG
exception (see [`../../architecture/deploy.md`](../../architecture/deploy.md)), and the PWA ring limits are
exactly what motivates the [mobile pivot plan](../mobile/).

## Biggest open risks

> [!NOTE]
> These were the two risks identified before the build. Both were resolved — the resolutions are recorded above and in the linked files. Kept here as the design record.

- **TURN ingress vs. "no public ports."** coturn needs publicly reachable UDP (3478 + a relay port range) and/or TCP/TLS 5349. Cloudflare Tunnel carries only HTTP/WebSocket, **not arbitrary UDP**, so TURN cannot ride the existing tunnel. This forces a deliberate exception to the no-public-ports ingress model. The options (VM public IP behind strict NSG, Cloudflare Spectrum, TURN-over-TLS on 443/5349, dedicated relay host) and the recommended default are worked through in **[03-infrastructure-turn-and-networking.md](./03-infrastructure-turn-and-networking.md)**.
- **PWA call UX.** No CallKit/ConnectionService, unreliable background ring, and Web Push wake constraints (iOS only on 16.4+ installed PWAs) mean an incoming call may not reliably wake the device or ring. Honest limits and realistic mitigations are in **[05-frontend-pwa-and-webrtc.md](./05-frontend-pwa-and-webrtc.md)**; the user-facing privacy impact is in **[06-threat-model-and-privacy.md](./06-threat-model-and-privacy.md)**.

Both risks, plus anything still undecided, are tracked in **[09-decision-log-and-open-questions.md](./09-decision-log-and-open-questions.md)**.
