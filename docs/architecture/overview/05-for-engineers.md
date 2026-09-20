# For engineers

A reading path for someone about to change this code: what the pieces are,
how the two flows that matter actually work, and the rules a change has to
satisfy. Four stops.

## The pieces, and which ones are not what they look like

Two applications, two datastores, a relay and an ingress. Three things are
easy to misread:

- **The Web PWA is a container that runs in the browser.** In production its
  built `dist/` is baked into the ingress image, so nothing serves it as its
  own process.
- **The API is one process** serving both the REST API and the WebSocket
  gateway. There is no separate gateway service.
- **`@argus/contracts` and `@argus/crypto` are libraries, not containers** —
  compiled into the API and the PWA, not separately runnable.

![Container view: the running pieces and how a message travels between them](embed:Containers)

- [ADR 2: use MLS through the ts-mls library](https://github.com/Dezoxy/secmes/blob/main/docs/architecture/decisions/0002-use-mls-through-ts-mls.md)

## Sending a message

Six steps. The thing to keep in mind while changing any of them: the server's
entire job is to store and forward an envelope it cannot open. A feature that
needs the server to understand content is not a feature that can be built here.

![Message flow view: sending one message, end to end](embed:MessageFlow)

## Starting a call

Signalling travels as ciphertext over the **existing message socket** rather
than a separate channel, and media never goes peer-to-peer: relay-only
transport is forced server-side, not requested politely by the client, so
neither party learns the other's address.

![Call setup view: establishing a 1:1 audio call](embed:CallSetup)

## What a change has to satisfy

The six invariants in [`AGENTS.md`](https://github.com/Dezoxy/secmes/blob/main/AGENTS.md)
are the hard ones — a change that violates one is wrong even if it works. In
practice the three that bite most often:

- **Never log message content, keys, tokens or presigned URLs.** Logs carry
  identifiers and metadata only.
- **A new table needs `tenant_id` and an enforced RLS policy.** No exceptions.
- **A new or changed controller needs a spec** pinning its guard posture and
  status contract.

- [Principles](https://github.com/Dezoxy/secmes/blob/main/docs/architecture/principles/architecture-principles.md): the rules of thumb, and where each does not apply
- [Constraints](https://github.com/Dezoxy/secmes/blob/main/docs/architecture/requirements/constraints.md): what was fixed before the design started
- [Integration](https://github.com/Dezoxy/secmes/blob/main/docs/architecture/integration/integration-architecture.md): every external system and what happens when it is gone
