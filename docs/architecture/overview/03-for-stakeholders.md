# For stakeholders

A reading path for someone deciding whether this should exist, and what it
promises the people who use it. No hostnames, no protocols, no tables of
settings. Four stops.

## What it is and who uses it

argus is a private messenger you can only join by invitation. Members send
messages; administrators mint the invitations and can see who exists, never
what anyone said. It leans on a small number of outside services — Cloudflare
to reach it, Backblaze to hold encrypted files, Azure to hold its secrets.

![Context view: who uses argus and which outside services it depends on](embed:SystemContext)

## The promise, and what happens when you send a message

The promise is one sentence: **the server stores and forwards messages it
cannot read.** Not "does not read" — *cannot*. It holds no key that would open
them.

Six steps take a message from a member to the people it is for. Every step the
server performs is on bytes that are meaningless to it.

![Message flow view: sending one message, end to end](embed:MessageFlow)

- [What argus is](https://github.com/Dezoxy/secmes/blob/main/docs/architecture/overview/01-what-argus-is.md): the guarantee in plain
  language, and the two things it does not cover

## What it deliberately does not do

The same decision that makes the promise possible removes features people
expect. There is no search of message content, no moderation, no link
previews — each would need a key the server must not hold. And **if you lose
every device, your history is gone**: there is no reset, because a reset would
mean the operator holding something that could open your messages.

- [Scope](https://github.com/Dezoxy/secmes/blob/main/docs/architecture/overview/02-scope.md): what is in, what is out, and why
- [ADR 4: store no recoverable secret on the server](https://github.com/Dezoxy/secmes/blob/main/docs/architecture/decisions/0004-store-no-recoverable-secret-on-the-server.md)

## What could go wrong

Three things, and only one is about cryptography.

**The operator can still see metadata** — who talks to whom, when, how much.
That is protected by the operator behaving well, not by mathematics, and anyone
who needs to hide *that* they are talking to someone should not use argus.

**It runs on one machine.** If that machine is lost, the service is restored
from backup rather than failing over. That restore **has been practised once**,
on a copy — it worked, and it found a real problem that was then fixed. But it
has never been practised on the actual backups, and nobody has measured how
long it takes, so the recovery promise is partly evidence and partly still a
design.

**It is not actually deployed yet.** The production track is built and gated;
what runs today is an experiment holding no real data.

- [Architecture risks](https://github.com/Dezoxy/secmes/blob/main/docs/architecture/risks/architecture-risks.md)
- [Where it stands and what is next](https://github.com/Dezoxy/secmes/blob/main/docs/architecture/roadmap/roadmap.md)
