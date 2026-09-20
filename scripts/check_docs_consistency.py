#!/usr/bin/env python3
"""Fail when documentation contradicts the tree it documents.

The mechanical half of the /docs-sync audit (.claude/skills/docs-sync/SKILL.md).
It only checks claims derivable from the repo: mirrored files, resolvable
links, indexes, ADR format, the view register and cross-referenced IDs. A green
run means "nothing provably false", not "docs are good".

Every check whose subject is missing is skipped, not failed, so a repository
adopts them as it grows: no docs index, no view register, no speaker notes and
no requirement documents still passes. What exists must be consistent.

The canonical copy lives in architecture-base (scripts/); repositories copy it
unchanged.

Run from anywhere: python3 scripts/check_docs_consistency.py
"""

from __future__ import annotations

import os
import re
import subprocess
import sys
from functools import lru_cache
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
ARCH = REPO / "docs" / "architecture"
ADR_DIR = ARCH / "decisions"
ARCH_INDEX = ARCH / "README.md"
DOCS_INDEX = REPO / "docs" / "README.md"
VIEWS_DSL = ARCH / "model" / "views.dsl"

# Generated output and templates with example links are not documentation.
# `worktrees` is where Claude Code puts session-local agent checkouts; it holds
# whole copies of the repository, so scanning it double-reports the real tree.
SKIP_DIRS = {"generated", "templates", "node_modules", "vendor", ".git", "worktrees"}
# Vendored rule sets (for example ECC's) keep upstream's relative links to
# directories installed globally, not in this repo. They are not documentation.
VENDORED = REPO / ".claude" / "rules"

# Cited ID pattern -> the file that must define it (as a table row or heading).
ID_OWNERS = {
    r"\bC-\d{2}\b": ARCH / "requirements" / "constraints.md",
    r"\bQA-\d{2}\b": ARCH / "requirements" / "quality-attributes.md",
    r"\bA-\d{2}\b": ARCH / "requirements" / "assumptions.md",
    r"\bP-\d{2}\b": ARCH / "principles" / "architecture-principles.md",
    r"\bRISK-\d{3}\b": ARCH / "risks" / "architecture-risks.md",
    r"\bTD-\d{3}\b": ARCH / "risks" / "technical-debt.md",
    r"\bT-\d{2}\b": ARCH / "security" / "threat-model.md",
}

ADR_NAME = re.compile(r"^(\d{4})-[a-z0-9]+(?:-[a-z0-9]+)*\.md$")
ADR_STATUSES = {"Proposed", "Accepted", "Rejected", "Deprecated", "Superseded"}
LINK_RE = re.compile(r"\[([^\]]+)\]\(([^)\s]+)\)")
# Documents imported into Structurizr's Documentation tab cannot use relative
# links: the tab renders them outside the repository tree, so `../risks/x.md`
# resolves to nothing for the reader. They link by absolute URL instead, which
# check_links() skips along with every other http(s) link. Set this to the
# repository's own "owner/name" and those links are checked on disk again.
# Leave it None and the check is skipped.
SELF_REPO: str | None = "Dezoxy/secmes"
INLINE_CODE = re.compile(r"`[^`]*`")
PROSE_WIDTH = 80
# Copied skills stay byte-identical to their canonical source, so a consuming
# repository does not get to rewrap them.
SKILL_DIRS = (REPO / ".claude" / "skills", REPO / ".agents" / "skills")
OVERVIEW = ARCH / "overview"
# overview/ IS the imported folder, so its own files need no pointer. ADRs are
# imported by `!adrs`, not `!docs`, and reach the document by their own route.
NOT_SYMLINKED = {"overview", "decisions"}
FENCE = re.compile(r"^\s*(```|~~~)")


class Failures(list):
    def add(self, check: str, detail: str) -> None:
        self.append((check, detail))


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def rel(path: Path) -> str:
    return path.relative_to(REPO).as_posix()


def prose(text: str) -> str:
    """The text outside fenced blocks: a sample ADR or risk is an example, not a claim."""
    out, fenced = [], False
    for line in text.splitlines():
        if FENCE.match(line):
            fenced = not fenced
        elif not fenced:
            out.append(line)
    return "\n".join(out)


def markdown_files() -> list[Path]:
    """Every document this repository authors, wherever it sits.

    Three roots hold documentation wholesale -- docs/, .claude/, .agents/ --
    and the instruction files sit at the top. Everything else that documents a
    part of the tree does so as a README.md beside the thing it describes: a
    Terraform module, a service, a package. Those go stale exactly like the
    rest, and used to be unreachable by every check here, so they are collected
    too.

    That last pass skips dot-directories. They hold caches and vendored
    downloads -- .terraform/ ships a README with every provider it unpacks --
    and those documents belong to somebody else. The two dot-directories this
    repository does own are named as roots above, so nothing is lost.
    """
    roots = [REPO / "docs", REPO / ".claude", REPO / ".agents"]
    files = [REPO / p for p in ("README.md", "AGENTS.md", "CLAUDE.md")]
    for root in roots:
        files += [
            p
            for p in root.rglob("*.md")
            if not SKIP_DIRS.intersection(p.relative_to(REPO).parts)
            and VENDORED not in p.parents
            # A symlink into overview/ is an alias for a document that already
            # appears under its own folder. Counting it twice would demand its
            # own index entry and report every finding in it twice.
            and not p.is_symlink()
        ]
    collected = {p.resolve() for p in files}
    files += [
        p
        for p in REPO.rglob("README.md")
        if p.resolve() not in collected
        and not SKIP_DIRS.intersection(p.relative_to(REPO).parts)
        and not any(part.startswith(".") for part in p.relative_to(REPO).parts)
        and not p.is_symlink()
    ]
    present = [p for p in files if p.exists()]
    return [p for p in present if p not in git_ignored(present)]


@lru_cache(maxsize=1)
def _ignored(paths: tuple[Path, ...]) -> frozenset[Path]:
    """The subset of `paths` that git ignores, resolved in one call.

    LOCAL CHANGE (report upstream): markdown_files() describes its result as
    "every document this repository authors", but the sweep reaches generated
    and scratch trees too -- here `ds-bundle/` (design-sync build output) and
    `/spike/` ("throwaway spikes -- never product code"), both gitignored. CI
    never sees them, so they cannot fail the gate there; locally they fail it
    permanently, which teaches people that a red `make docs` is normal. A file
    git does not track is not a document this repository authors.

    One batched call, not one per file: this runs over ~180 paths. `-z` on both
    sides is load-bearing -- without it git quotes any path holding a non-ASCII
    character ("na\303\257ve doc.md"), which would never match the Path it came
    from, so that file would silently slip back into the checks.
    """
    try:
        done = subprocess.run(
            ["git", "-C", str(REPO), "check-ignore", "-z", "--stdin"],
            input="\0".join(str(p) for p in paths),
            capture_output=True,
            text=True,
        )
    except (OSError, subprocess.SubprocessError):
        return frozenset()  # no git: fall back to checking everything
    return frozenset(Path(name) for name in done.stdout.split("\0") if name)


def git_ignored(paths: list[Path]) -> frozenset[Path]:
    return _ignored(tuple(paths))


def check_twins(f: Failures) -> None:
    """AGENTS.md and CLAUDE.md carry the same instructions, byte for byte."""
    if read(REPO / "AGENTS.md") != read(REPO / "CLAUDE.md"):
        f.add(
            "twins",
            # LOCAL CHANGE (not an upstream bug): architecture-base edits
            # CLAUDE.md and copies it to AGENTS.md. This repository is the other
            # way round -- AGENTS.md is the canonical contract, read natively by
            # Codex -- so upstream's wording would send a confused reader to the
            # wrong file at the exact moment they are looking for direction.
            # The check itself is symmetric; only the advice differs.
            "AGENTS.md and CLAUDE.md differ; edit AGENTS.md, then cp AGENTS.md CLAUDE.md",
        )


def check_skill_mirror(f: Failures) -> None:
    """.agents/skills/ mirrors .claude/skills/ byte for byte."""
    claude, agents = REPO / ".claude" / "skills", REPO / ".agents" / "skills"
    for src in sorted(claude.glob("*/SKILL.md")):
        mirror = agents / src.parent.name / "SKILL.md"
        if not mirror.exists():
            f.add("skill-mirror", f"{rel(src)} has no mirror at {rel(mirror)}")
        elif mirror.read_bytes() != src.read_bytes():
            f.add(
                "skill-mirror",
                f"{rel(mirror)} differs from {rel(src)} (the .claude/ copy is the source)",
            )
    for mirror in sorted(agents.glob("*/SKILL.md")):
        if not (claude / mirror.parent.name / "SKILL.md").exists():
            f.add(
                "skill-mirror", f"{rel(mirror)} mirrors a skill that no longer exists"
            )


def check_links(f: Failures) -> None:
    """Every relative markdown link resolves to something on disk.

    `embed:` is Structurizr's scheme for showing a view inside a documentation
    page. It names a view key, not a file, so it has nothing to resolve. Only
    an embed carrying alt text reaches here at all, because the link pattern
    needs a non-empty label.
    """
    for src in markdown_files():
        for text, link in LINK_RE.findall(prose(read(src))):
            if link.startswith(("http://", "https://", "#", "mailto:", "embed:")):
                continue
            if not (src.parent / link.split("#")[0]).exists():
                f.add("links", f"{rel(src)}: [{text}]({link}) does not resolve")


def check_docs_index(f: Failures) -> None:
    """Every doc under docs/ is linked from docs/README.md or the architecture README."""
    if not DOCS_INDEX.exists():
        return  # a repository without a docs index has nothing to enforce
    indexes = {DOCS_INDEX: read(DOCS_INDEX), ARCH_INDEX: read(ARCH_INDEX)}
    for doc in sorted((REPO / "docs").rglob("*.md")):
        parts = doc.relative_to(REPO).parts
        if doc in indexes or SKIP_DIRS.intersection(parts) or "decisions" in parts:
            continue
        linked = any(
            (index.parent / link.split("#")[0]).resolve() == doc.resolve()
            for index, text in indexes.items()
            for _, link in LINK_RE.findall(text)
            if not link.startswith(("http://", "https://", "#"))
        )
        if not linked:
            f.add(
                "docs-index",
                f"{rel(doc)} is not linked from docs/README.md or {rel(ARCH_INDEX)}",
            )


def check_adrs(f: Failures) -> None:
    """ADRs import cleanly into Structurizr and are listed in the architecture README."""
    if not ADR_DIR.is_dir():
        return
    index = read(ARCH_INDEX)
    numbers = []
    for path in sorted(ADR_DIR.iterdir()):
        match = ADR_NAME.match(path.name)
        if not path.is_file() or not match:
            f.add(
                "adrs",
                f"{rel(path)}: only NNNN-kebab-title.md files belong in decisions/",
            )
            continue
        number = int(match.group(1))
        numbers.append(number)
        lines = read(path).splitlines()
        if not lines or not lines[0].startswith(f"# {number}. "):
            f.add("adrs", f"{rel(path)}: first line must be '# {number}. <title>'")
        if not any(re.fullmatch(r"Date: \d{4}-\d{2}-\d{2}", ln) for ln in lines):
            f.add("adrs", f"{rel(path)}: needs a 'Date: YYYY-MM-DD' line")
        if "## Status" not in lines or "## Context" not in lines:
            f.add("adrs", f"{rel(path)}: needs '## Status' followed by '## Context'")
        else:
            start, end = lines.index("## Status"), lines.index("## Context")
            status = next((ln for ln in lines[start + 1 : end] if ln.strip()), "")
            if status.split(" ")[0] not in ADR_STATUSES:
                f.add(
                    "adrs",
                    f"{rel(path)}: status must start with one of {sorted(ADR_STATUSES)}",
                )
        if f"(decisions/{path.name})" not in index:
            f.add("adrs", f"{rel(path)} is not listed in {rel(ARCH_INDEX)}")
    if numbers and sorted(numbers) != list(range(1, len(numbers) + 1)):
        f.add(
            "adrs",
            f"ADR numbers must run 1..{len(numbers)} without gaps: {sorted(numbers)}",
        )


def check_view_register(f: Failures) -> None:
    """The README view register lists exactly the views defined in views.dsl."""
    if not VIEWS_DSL.exists() or "## View register" not in read(ARCH_INDEX):
        return  # no register to reconcile yet
    dsl = read(VIEWS_DSL)
    defined = set(
        re.findall(
            r"^(?:systemLandscape|systemContext\s+\S+|container\s+\S+|component\s+\S+|"
            r'dynamic\s+\S+|deployment\s+\S+\s+\S+)\s+"([^"]+)"',
            dsl,
            re.MULTILINE,
        )
    )
    section = read(ARCH_INDEX).split("## View register", 1)
    registered = (
        set(
            re.findall(
                r"^\|\s*([A-Za-z][A-Za-z0-9]+)\s*\|",
                section[1].split("\n## ", 1)[0],
                re.MULTILINE,
            )
        )
        - {"Key"}
        if len(section) == 2
        else set()
    )
    for key in sorted(defined - registered):
        f.add(
            "view-register",
            f"view '{key}' is in views.dsl but not in the README view register",
        )
    for key in sorted(registered - defined):
        f.add(
            "view-register",
            f"view '{key}' is in the README view register but not in views.dsl",
        )


def check_speaker_notes(f: Failures) -> None:
    """Every view in views.dsl has a '### <key>' section in the speaker notes."""
    notes_path = ARCH / "talks" / "speaker-notes.md"
    if not notes_path.exists() or not VIEWS_DSL.exists():
        return  # speaker notes are optional; enforce them once they exist
    notes = set(re.findall(r"^### (\S+)\s*$", read(notes_path), re.MULTILINE))
    defined = set(
        re.findall(
            r"^(?:systemLandscape|systemContext\s+\S+|container\s+\S+|component\s+\S+|"
            r'dynamic\s+\S+|deployment\s+\S+\s+\S+)\s+"([^"]+)"',
            read(VIEWS_DSL),
            re.MULTILINE,
        )
    )
    for key in sorted(defined - notes):
        f.add("speaker-notes", f"view '{key}' has no section in {rel(notes_path)}")
    for key in sorted(notes - defined):
        f.add(
            "speaker-notes",
            f"{rel(notes_path)} has a section for '{key}', which is not a view",
        )


def check_ids(f: Failures) -> None:
    """Every cited requirement/risk ID is defined in its owning document."""
    sources = markdown_files() + sorted(ARCH.rglob("*.dsl"))
    for pattern, owner in ID_OWNERS.items():
        if not owner.exists():
            continue  # this repository does not keep that ID family
        owner_text = read(owner)
        defined = set(
            re.findall(
                r"^(?:\|\s*|#+\s*)(" + pattern.strip(r"\b") + r")\b",
                owner_text,
                re.MULTILINE,
            )
        )
        for src in sources:
            for cited in sorted(set(re.findall(pattern, prose(read(src))))):
                if cited not in defined:
                    f.add(
                        "ids",
                        f"{rel(src)} cites {cited}, which {rel(owner)} does not define",
                    )


def check_self_links(f: Failures) -> None:
    """Absolute links back into this repository resolve to a real file.

    Inline code is stripped first: a URL inside backticks is an example of the
    form to use, not a claim that a file exists. Writing the convention down
    must not fail the check that enforces it.
    """
    if not SELF_REPO:
        return  # this repository has not declared its own name
    pattern = re.compile(
        rf"https://github\.com/{re.escape(SELF_REPO)}/blob/[^/]+/([^)#\s]+)"
    )
    for src in markdown_files():
        for path in pattern.findall(INLINE_CODE.sub("", prose(read(src)))):
            if not (REPO / path).exists():
                f.add(
                    "self-links",
                    f"{rel(src)}: a link to {path} does not resolve",
                )


def check_line_width(f: Failures) -> None:
    """Prose wraps, so a one-word edit does not rewrite a whole paragraph's diff.

    Only prose. A table row is as wide as its widest cell and a fenced block is
    code; neither can wrap, and a formatter that pads them makes the problem
    worse rather than better -- measured: aligning this repository's tables took
    its longest line from 815 columns to 1015. A line held over the limit by a
    single unbreakable token, such as an absolute URL, is left alone because
    there is nowhere to break it. An image line is left alone because splitting
    `![alt](embed:Key)` stops the PDF builder recognising the embed.
    """
    for src in markdown_files():
        if any(d in src.parents for d in SKILL_DIRS):
            continue
        fenced = False
        lines = read(src).splitlines()
        # LOCAL CHANGE (report upstream): YAML frontmatter is data, not prose.
        # An agent or skill definition declares `description:` as a single-line
        # scalar, and the tools that read it -- Claude Code registers a subagent
        # from this block -- require it on one line. Wrapping it silently
        # unregisters the agent while leaving every word in place, which is how
        # it slipped past both a word-identity and a structure proof once.
        # Same reasoning as SKILL_DIRS above: a consuming repository does not
        # get to rewrap a file another tool parses.
        start = 1
        if lines and lines[0].rstrip() == "---":
            end = next(
                (i for i, ln in enumerate(lines[1:], 1) if ln.rstrip() == "---"), None
            )
            if end is not None:
                lines, start = lines[end + 1 :], end + 2
        for number, line in enumerate(lines, start):
            if FENCE.match(line):
                fenced = not fenced
                continue
            if fenced or line.lstrip().startswith(("|", "#", "![")):
                continue
            if len(line) <= PROSE_WIDTH:
                continue
            if len(line) - max((len(w) for w in line.split()), default=0) <= PROSE_WIDTH:
                continue
            f.add(
                "line-width",
                f"{rel(src)}:{number}: prose line is {len(line)} columns, "
                f"over {PROSE_WIDTH}; wrap it",
            )


def check_overview_complete(f: Failures) -> None:
    """Every architecture document reaches the Documentation tab and the PDF.

    Structurizr imports overview/ and does not recurse, so a document is in the
    tab -- and therefore in the PDF, which is built from the same folder -- only
    if a file in overview/ points at it. Registers stay in their own folders,
    where their IDs are owned, and are symlinked in as NN-name.md; each is
    authored once and the number fixes its order. A register nobody symlinked is
    invisible in the artifact people are handed, while still looking present in
    the repository.
    """
    if not OVERVIEW.is_dir():
        return
    linked = set()
    for link in sorted(OVERVIEW.iterdir()):
        if not (link.is_symlink() and link.suffix == ".md"):
            continue
        # Deleting a register the repository does not need is right; leaving
        # its symlink behind is not. A dangling link is a section of the
        # document that points at nothing.
        if not link.exists():
            f.add(
                "overview-complete",
                f"{rel(link)} points at {os.readlink(link)}, which does not "
                f"exist; delete the symlink too",
            )
            continue
        linked.add(link.resolve())
    for doc in sorted(ARCH.rglob("*.md")):
        parts = doc.relative_to(ARCH).parts
        if len(parts) == 1 or parts[0] in NOT_SYMLINKED:
            continue
        if SKIP_DIRS.intersection(parts) or doc.is_symlink():
            continue
        if doc.resolve() not in linked:
            f.add(
                "overview-complete",
                f"{rel(doc)} is in no reading path: symlink it into "
                f"{rel(OVERVIEW)}/ as NN-name.md, or it stays out of the PDF",
            )


CHECKS = (
    check_twins,
    check_skill_mirror,
    check_links,
    check_self_links,
    check_line_width,
    check_docs_index,
    check_overview_complete,
    check_adrs,
    check_view_register,
    check_speaker_notes,
    check_ids,
)


def main() -> int:
    failures = Failures()
    for check in CHECKS:
        check(failures)
    if not failures:
        print(f"docs consistency: {len(CHECKS)} checks passed")
        return 0
    print("docs consistency: documentation contradicts the tree\n", file=sys.stderr)
    for name, detail in failures:
        print(f"  [{name}] {detail}", file=sys.stderr)
    print(
        "\nFix the docs in this branch. See .claude/skills/docs-sync/SKILL.md.",
        file=sys.stderr,
    )
    return 1


if __name__ == "__main__":
    sys.exit(main())
