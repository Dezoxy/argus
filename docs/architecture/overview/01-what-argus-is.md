# What argus is, and what it guarantees

argus is a private messenger. You join only by redeeming a code an
administrator minted for you, and from then on you sign in with a passkey —
there is no password anywhere in the system.

Messages are **end-to-end encrypted**. That phrase is used loosely in the
industry, so here is precisely what it means in argus: the server stores and
forwards bytes it cannot read, and it holds no key that could open them.
Encryption and decryption happen only on your device.

That guarantee is not a promise about the operator's good behaviour. It is a
property of how the system is built. If someone gained complete control of the
server, read its disks and took its backups, they would obtain ciphertext.

![Context view: who uses argus and which outside services it depends on](embed:SystemContext)

## What it does not protect

**Metadata.** The server must know who to deliver a message to, so it knows who
is talking to whom, when, and roughly how much. That is protected by access
control — by the operator being careful — not by cryptography. It is a weaker
promise, and it is written down as a risk rather than glossed over.

If you need to hide *that* you are talking to someone, and not only *what* you
said, argus is not the right tool.

## What you lose if you lose your devices

Everything. There is no password reset and no way for the operator to restore
your history, because building one would mean the server holding something that
could open your messages — which is precisely what the guarantee above forbids.

The answer is to register a second device before you need it. That is not a
workaround; it is the recovery mechanism.

## Who uses it

- **Members** send messages, join groups, share encrypted attachments and make
  1:1 audio calls.
- **Tenant administrators** mint and revoke invite codes, list members and
  devices, and read an audit log. They see metadata only. There is no
  administrative path to message content, and adding one would break the
  guarantee.
- **Operators** watch dashboards and error reports, reaching them through a
  separate identity gate rather than through an argus account.

## What happens when you send a message

Six steps, and every one the server performs is on bytes it cannot interpret.

![Message flow view: sending one message, end to end](embed:MessageFlow)

## How to read the rest

**Pick the path for your question rather than reading straight through.** Each
one is short, embeds the diagrams that answer it, and links to the document
that owns each fact.

- **For stakeholders** — should this exist, and what does it promise?
- **For the CTO** — does the design hold, and what is unproven?
- **For engineers** — what are the pieces, and what must a change satisfy?
- **For operators** — how does a change land, what watches it, what happens
  when the machine is gone?

After the paths come the registers, each owning its own facts: **Scope** and
**Glossary**; **Principles** and **Constraints**; **Quality attributes**, each
with its evidence or an admission there is none; **Assumptions**; then **Trust
boundaries**, **Data**, **Integration**, **Deployment**, **Reliability** and
**Observability**; and finally **Risks**, **Technical debt** and the
**Roadmap**.

The decision records explain *why* each significant choice was made, including
the alternatives that were rejected and what each choice cost.
