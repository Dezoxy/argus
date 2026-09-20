# Assumptions

Things taken to be true that are not proven here. An assumption that turns out
false invalidates whatever depends on it, so each one names what it would break.

| ID | Assumption | If it is false | Recheck when |
| --- | --- | --- | --- |
| A-01 | Members' browsers support WebAuthn with the PRF extension. | Those members cannot unlock a device keystore at all; passkey-only login becomes unusable for them. | A supported-browser complaint arrives, or before any public beta. |
| A-02 | `ts-mls` remains maintained and its wire format stays compatible. | The crypto core needs replacing, which touches every client. Migration would be expensive. | On each dependency review; immediately on an unmaintained signal. |
| A-03 | Cloudflare remains available and the tunnel keeps working. | The service is unreachable. There is no second ingress path by design. | After any Cloudflare incident affecting the tunnel. |
| A-04 | The single VM's capacity is sufficient for the expected member count. | Vertical scaling is the only lever; the architecture has no horizontal path today. | Before any growth beyond an invited pilot group. |
| A-05 | One nightly backup cycle is an acceptable recovery point. | Point-in-time recovery becomes necessary, which means WAL archiving and a larger operational surface. | When argus holds data whose loss would matter to someone other than the operator. |
| A-06 | Metadata visible to the operator is acceptable to members. | The privacy proposition is weaker than advertised and needs either a design change or an honest disclosure. | Before any public launch. |

Ownership of every assumption is the solo operator; there is no second party to
assign them to, and inventing one would be fiction.
