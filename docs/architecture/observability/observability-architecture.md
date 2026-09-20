## Observability

How a failure becomes a signal someone acts on. Twelve containers watch six,
which is a deliberate exception to
[P-02](https://github.com/Dezoxy/secmes/blob/main/docs/architecture/principles/architecture-principles.md): an unattended single VM that
cannot be observed fails silently.

### The signals

| Signal | Collected by | Stored in | Retention |
| --- | --- | --- | --- |
| Metrics | Prometheus scrapes the API, the datastore exporters and the relay | Prometheus | 15 days |
| Logs | Alloy tails container logs from the host, read-only | Loki | 7 days |
| Traces | The API exports OTLP, sampled | Tempo | 72 hours |
| Profiles | The API pushes continuously | Pyroscope | 72 hours |
| Errors | The API reports exceptions | GlitchTip, with its own worker and its own database | Per GlitchTip |
| Alerts | Prometheus rules fire into Alertmanager | Delivered to a webhook receiver | — |

Grafana reads all four stores and is the single place an operator looks.

### What is deliberately not exposed

- **The API's metrics port is internal and unauthenticated.** That is safe only
  because it is unreachable: no host port is published, and it is not routed
  through the ingress. The Compose file says so in a comment, and CI asserts the
  invariant it depends on.
- **Alloy is given no Docker socket.** It reads container log files from the
  host read-only. A log collector with a Docker socket is root on the host.
- **Grafana and GlitchTip are reachable**, on their own hostnames, gated by
  Cloudflare Access. Anonymous access and sign-up are both disabled in Grafana.

### The rule that governs all of it

No signal may carry message content. Logs carry identifiers and metadata;
traces carry spans, not payloads; error reports carry stack traces. This is not
a convention to remember — it is one of the six invariants in `AGENTS.md`, and
violating it in a log line is a blocking review finding.

### The gap

All of this runs on the machine it is watching. It reports application faults
well and host death not at all: if the VM stops, so does everything that would
tell you. An external uptime check is the missing piece, tracked as
[TD-004](https://github.com/Dezoxy/secmes/blob/main/docs/architecture/risks/technical-debt.md).

A second, quieter gap: alerts go to a webhook whose URL is a secret and whose
identity is not recorded in this repository. If that receiver is
misconfigured, alerts fire into nothing and the failure is invisible by
construction.
