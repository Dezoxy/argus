# 6. Expose no inbound port except the call relay

Date: 2026-09-20

## Status

Accepted

## Context

A single VM with a public IP is scanned continuously. Every open port is an
attack surface that has to be defended forever, and the usual answer — open 443,
put a reverse proxy behind it, keep the proxy patched — still leaves a service
answering unauthenticated requests from the whole internet.

Cloudflare Tunnel inverts this: the VM dials out to Cloudflare and requests
arrive down that connection. Nothing listens for inbound connections.

The exception is call media. WebRTC needs UDP, and a tunnel cannot carry it.

## Decision drivers

- [QA-04](../requirements/quality-attributes.md) — the VM must expose no
  unauthenticated service to the internet.
- [C-04](../requirements/constraints.md) — one operator; a surface that needs
  constant attention is a surface that will eventually be neglected.

## Considered options

1. Open 80 and 443, terminate TLS on the VM behind a firewall.
2. Put a cloud load balancer in front with a WAF.
3. Outbound-only Cloudflare Tunnel, with an explicit exception for media.

## Decision

We will expose nothing inbound except the coturn media ports. The firewall's
only Allow rules are TURN: 3478 and 5349, plus the relay range. There is no 22,
no 80 and no 443. HTTP reaches the VM only through the outbound tunnel, and
deploys run through the cloud control plane rather than over SSH.

CI enforces the shape of this: it asserts that no Compose service publishes a
host port, and that coturn is the only host-network service.

## Consequences

Positive:

- Port scanning finds a media relay and nothing else. There is no login prompt
  on the public internet.
- TLS, WAF and rate limiting happen at Cloudflare's edge, off the VM.
- No SSH key to manage, rotate or lose.

Negative / accepted trade-offs:

- Cloudflare becomes a hard dependency for all reachability, and the tunnel's
  hostname routing lives in their dashboard rather than in this repository —
  configuration that is not in git.
- The relay ports are genuinely internet-exposed and must be kept patched. They
  are marked `Internet-exposed` in the model so nobody forgets.
- Debugging a broken tunnel requires the cloud console, because there is no
  fallback way in.

## Risks

- [RISK-005](../risks/architecture-risks.md) — reachability depends entirely on
  Cloudflare, and part of that configuration is not in version control.

## Related

- Requirements: [QA-04](../requirements/quality-attributes.md)
- Architecture views: AccessPaths, AzureDeployment
- Other ADRs: [5. Run on one VM with Docker Compose](0005-run-on-one-vm-with-docker-compose.md)
