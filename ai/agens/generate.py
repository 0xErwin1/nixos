#!/usr/bin/env python3
"""Regenerate the agens harness tree from the shared canonical sources.

Everything under `ai/agens/` except `config.toml`, this script, and `README.md`
is generated. Run this after changing `ai/shared/`, `ai/claude/agents`,
`ai/claude/commands`, `ai/command`, or `ai/skills`, then run
`home-manager switch` to copy the result into `~/.config/agens/`.

See README.md for why each transformation exists.
"""

import json
import re
import shutil
import sys
from pathlib import Path

AI = Path(__file__).resolve().parent.parent
TARGET = AI / "agens"

AGENT_SOURCE = AI / "claude/agents"
COMMAND_SOURCES = [AI / "claude/commands", AI / "command"]
SKILL_SOURCES = [AI / "skills", AI / "claude/skills"]

MAX_DESCRIPTION = 1024
NAME_PATTERN = re.compile(r"^[a-z0-9]([a-z0-9-]*[a-z0-9])?$")

WRITE_TOOLS = {"Write", "Edit", "NotebookEdit", "MultiEdit"}
BASH_TOOLS = {"Bash", "BashOutput", "KillShell"}

# `upstream-ai-sync` reasons ABOUT the per-tool harness trees, so its `~/.claude`
# references are its subject matter, not paths it expects to read.
REWRITE_EXEMPT = {"upstream-ai-sync"}

REWRITES = [
    (re.compile(r"~/\.claude/CLAUDE\.md"), "~/.config/agens/AGENTS.md"),
    (re.compile(r"~/\.claude/skills/"), "~/.config/agens/skills/"),
    (re.compile(r"~/\.claude/agents/"), "~/.config/agens/agents/"),
    (re.compile(r"~/\.claude/commands/"), "~/.config/agens/commands/"),
    (re.compile(r"~/\.claude\b"), "~/.config/agens"),
]


def rewrite(text):
    for pattern, replacement in REWRITES:
        text = pattern.sub(replacement, text)
    return to_skill_invocations(text)


# Agens confines the `read` tool to the project root (`read_file_confined`), so
# nothing under ~/.config/agens is reachable by path. Harness documents are
# reached by NAME through the `skill` tool instead, which is why every path
# reference has to become a skill invocation -- an instruction to read a path
# outside the project is an instruction to fail.
SKILL_PATH = re.compile(r"`~/\.config/agens/skills/([a-z0-9-]+)/SKILL\.md`")
SHARED_PATH = re.compile(r"`~/\.config/agens/skills/_shared/([a-z0-9-]+\.md)`")
SHARED_DIR = re.compile(r"`~/\.config/agens/skills/_shared/`")
ORCHESTRATOR_PATH = re.compile(r"`~/\.config/agens/sdd-orchestrator\.md`")

# An agent definition is never read either: agens invokes an agent by name
# through the `task` tool, and the phase procedure itself lives in the
# orchestrator skill.
AGENT_PATH = re.compile(r"`~/\.config/agens/agents/[a-z0-9-]+\.md`")

# Applied after the path substitutions, to repair the verb phrases the originals
# wrapped those paths in ("read the skill file at X" -> "load the X skill").
READ_PHRASE = re.compile(
    r"\b(?P<verb>[Rr]ead)(?P<filler> the (?:skill|agent) file at| the file at)?"
    r" (?P<target>the `[^`]+` (?:skill|reference of))"
)

PHRASE_REPAIRS = [
    (re.compile(r"\bskill at (the `[^`]+` skill)", re.IGNORECASE), r"\1"),
    (
        re.compile(r"\bConvention files under (the references of the `[^`]+` skill)"),
        r"Conventions in \1",
    ),
]


def repair_read_phrase(match):
    """Turn a read-by-path phrase into a load-by-name one, keeping its case.

    The originals open sentences and numbered steps, so a blind lowercase
    replacement leaves "1. load the ..." mid-document.
    """
    verb = "Load" if match.group("verb")[0].isupper() else "load"
    return f"{verb} {match.group('target')}"


def to_skill_invocations(text):
    text = SKILL_PATH.sub(r"the `\1` skill", text)
    text = SHARED_PATH.sub(r"the `\1` reference of the `sdd-shared` skill", text)
    text = SHARED_DIR.sub("the references of the `sdd-shared` skill", text)
    text = ORCHESTRATOR_PATH.sub("the `sdd-orchestrator` skill", text)
    text = AGENT_PATH.sub("the `sdd-orchestrator` skill", text)

    text = READ_PHRASE.sub(repair_read_phrase, text)
    for pattern, replacement in PHRASE_REPAIRS:
        text = pattern.sub(replacement, text)
    return text


def valid_name(name):
    return bool(NAME_PATTERN.match(name)) and "--" not in name and len(name) <= 64


# --- instructions -----------------------------------------------------------


def build_instructions():
    """Compose AGENTS.md and the lazy-loaded orchestrator workflow.

    `ai/shared/AGENTS.md` is already tool-neutral and carries the Engram protocol
    and the writing-skill rules, so only the orchestrator section -- which every
    tool phrases in its own terms -- is grafted on, taken from the codex variant.
    """
    shared = (AI / "shared/AGENTS.md").read_text()
    codex = (AI / "codex/AGENTS.md").read_text()

    marker = "\n## SDD Orchestrator Instructions\n"
    tail = codex[codex.index(marker) :]
    tail = tail.replace("`~/.codex/sdd-orchestrator.md`", "the `sdd-orchestrator` skill")
    tail = re.sub(r"\b[Rr]ead (the `sdd-orchestrator` skill)", r"load \1", tail)
    tail = re.sub(r"\bCodex\b", "Agens", rewrite(tail))

    body = rewrite(
        shared.replace(
            "Use only the configured Atlas MCP tools for Atlas operations.",
            "Use only the configured Atlas MCP tools for Atlas operations in Agens.",
        ).replace(
            "Connection recovery is outside the agent's tool surface.",
            "Connection recovery is outside Agens's tool surface.",
        )
    )

    text = body.rstrip("\n") + "\n" + tail.rstrip("\n") + "\n" + HARNESS_ACCESS_NOTE
    (TARGET / "AGENTS.md").write_text(text)


HARNESS_ACCESS_NOTE = """
## Reaching harness documents

The `read` tool is confined to the project root, so nothing under
`~/.config/agens/` can be opened by path. Harness documents are reached by NAME
with the `skill` tool:

- A skill's instructions: `skill` with `{"skill": "<name>"}`.
- A skill's supporting document: `skill` with
  `{"skill": "<name>", "resource_class": "reference", "resource": "<file>.md"}`.

Shared SDD conventions live in the `sdd-shared` skill's references; the detailed
SDD and testing procedure is the `sdd-orchestrator` skill. If an instruction
anywhere names a path under `~/.config/agens/`, treat it as naming a skill and
load it that way -- do not try to read it.
"""


def build_orchestrator_skill():
    """Expose the lazy-loaded SDD procedure as a skill.

    It cannot be a plain file: `read` never reaches outside the project root, so
    a path reference to it is an instruction the agent can only fail.
    """
    orchestrator = (AI / "codex/sdd-orchestrator.md").read_text()
    orchestrator = orchestrator.replace("~/.codex/", "~/.config/agens/")
    orchestrator = re.sub(r"\bCodex\b", "Agens", rewrite(orchestrator))

    directory = TARGET / "skills/sdd-orchestrator"
    directory.mkdir(parents=True, exist_ok=True)
    (directory / "SKILL.md").write_text(
        "---\n"
        "name: sdd-orchestrator\n"
        'description: "The detailed SDD and testing procedure. '
        'Trigger: any SDD command, SDD phase delegation, or testing-pipeline intent."\n'
        "---\n\n" + orchestrator.lstrip("\n")
    )


def build_shared_skill():
    """Repackage `_shared/` as a skill whose documents are loadable references.

    The shared conventions are referenced by name from ~20 places. As a bare
    directory they are unreachable, since only skills can be loaded from outside
    the project root.
    """
    directory = TARGET / "skills/sdd-shared"
    references = directory / "references"

    shutil.rmtree(directory, ignore_errors=True)
    references.mkdir(parents=True)

    # Both trees are read: `ai/skills/_shared` carries `gh-convention.md`, and
    # only `ai/claude/skills/_shared` carries `sdd-orchestrator-workflow.md` and
    # `sdd-status-contract.md`, which the phases reference by name.
    names = []
    for source in (AI / "skills/_shared", AI / "claude/skills/_shared"):
        for path in sorted(source.glob("*.md")):
            if path.name == "README.md" or path.name in names:
                continue
            (references / path.name).write_text(rewrite(path.read_text()))
            names.append(path.name)
    names.sort()

    listing = "\n".join(f"- `{name}`" for name in names)
    (directory / "SKILL.md").write_text(
        "---\n"
        "name: sdd-shared\n"
        'description: "Shared SDD conventions and contracts referenced by the SDD phases. '
        'Trigger: any instruction naming a shared convention, contract, or phase-common document."\n'
        "---\n\n"
        "## Purpose\n\n"
        "Holds the conventions the SDD phases share. Each document is a reference on this "
        "skill, loaded with the `skill` tool:\n\n"
        '`{"skill": "sdd-shared", "resource_class": "reference", "resource": "<file>"}`\n\n'
        "## Available references\n\n" + listing + "\n"
    )

    # The bare directory would be dead weight: agens skips it for having no
    # manifest, and every reference to it now resolves through this skill.
    shutil.rmtree(TARGET / "skills/_shared", ignore_errors=True)


# --- agents -----------------------------------------------------------------


def split_frontmatter(text):
    if not text.startswith("---\n"):
        raise ValueError("missing frontmatter")
    end = text.index("\n---", 3)
    return text[4:end], text[end + 4 :].lstrip("\n")


def parse_frontmatter(block):
    """Read the flat `key: value` frontmatter Claude agents use.

    A line that does not open a new key continues the previous one, which is how
    the multi-paragraph descriptions are written.
    """
    fields = {}
    key = None
    for line in block.split("\n"):
        match = re.match(r"^([A-Za-z_-]+):\s?(.*)$", line)
        if match and not line.startswith(" "):
            key = match.group(1)
            fields[key] = match.group(2)
        elif key is not None:
            fields[key] += "\n" + line
    return fields


def single_line_description(raw):
    """Reduce a Claude description to one bounded line.

    Agens rejects control characters in a description and caps it at 1024
    characters. Everything from the first example block or blank line onward is
    dropped rather than flattened: those sections are few-shot examples, not
    summary text.
    """
    text = raw.strip()
    for marker in ("<example>", "\n\n", "Examples:", "Example:"):
        index = text.find(marker)
        if index > 0:
            text = text[:index]

    text = " ".join(text.split()).strip().strip('"').strip()
    if len(text) <= MAX_DESCRIPTION:
        return text

    cut = text[:MAX_DESCRIPTION]
    boundary = cut.rfind(" ")
    return (cut[:boundary] if boundary > 0 else cut).rstrip(" ,;:.") + "."


def permissions_for(tools_field):
    """Express Claude's tool allowlist as agens deny rules.

    Agens has no allowlist: it knows read, write/edit, list, search, and bash, and
    denies what a rule names. An absent or wildcard field leaves everything open.
    """
    if not tools_field:
        return []

    raw = tools_field.strip()
    if raw in {"*", "All tools"}:
        return []

    granted = {tool.strip() for tool in raw.split(",") if tool.strip()}

    rules = []
    if not granted & WRITE_TOOLS:
        rules.append("deny write")
    if not granted & BASH_TOOLS:
        rules.append("deny bash")
    return rules


# A subagent has no `skill` tool: agens only registers it on the parent turn, so
# an executor reaches a skill exclusively through the `skills:` field its own
# definition declares. Anything a body says to load has to be listed here, or the
# instruction is unreachable and the dispatcher rejects the preload outright.
SKILL_INVOCATION = re.compile(r"`([a-z0-9][a-z0-9-]*)` skill")

# The orchestrator procedure is the one exception: phase agents are told not to
# orchestrate, and the AGENT_PATH rewrite points at it only so the reference
# resolves for a reader.
SKILL_DECLARATION_EXEMPT = {"sdd-orchestrator"}


def available_skills():
    names = {"sdd-shared", "sdd-orchestrator"}
    for source in SKILL_SOURCES:
        names.update(
            directory.name for directory in source.iterdir() if directory.is_dir()
        )
    names.discard("_shared")
    return names


def declared_skills(body, catalog):
    """List the skills an agent's own instructions tell it to load.

    Order follows first mention so the generated field reads like the body, and
    an unknown name is dropped rather than emitted: agens rejects the whole
    definition when a declared skill is not in the catalog.
    """
    found = []
    for name in SKILL_INVOCATION.findall(body):
        if name in found or name in SKILL_DECLARATION_EXEMPT or name not in catalog:
            continue
        found.append(name)
    return found


def convert_agent(path, catalog):
    frontmatter, body = split_frontmatter(path.read_text())
    fields = parse_frontmatter(frontmatter)

    name = fields.get("name", path.stem).strip()
    if name != path.stem:
        raise ValueError(f"name {name!r} does not match filename {path.stem!r}")
    if not valid_name(name):
        raise ValueError(f"name {name!r} is not a valid agens catalog name")

    description = single_line_description(fields.get("description", ""))
    if not description:
        raise ValueError("description is empty")

    body = rewrite(body.strip())
    if not body:
        raise ValueError("body is empty")

    # Descriptions routinely contain ": ", which YAML reads as a nested mapping
    # unless the scalar is quoted.
    lines = [
        "---",
        f"name: {name}",
        f"description: {json.dumps(description, ensure_ascii=False)}",
        "mode: subagent",
    ]

    skills = declared_skills(body, catalog)
    if skills:
        lines.append("skills:")
        lines.extend(f"  - {skill}" for skill in skills)

    permissions = permissions_for(fields.get("tools"))
    if permissions:
        lines.append("permissions:")
        lines.extend(f"  - {rule}" for rule in permissions)

    lines.extend(["---", "", body, ""])
    return name, "\n".join(lines)


def build_agents():
    target = TARGET / "agents"
    shutil.rmtree(target, ignore_errors=True)
    target.mkdir(parents=True)

    catalog = available_skills()
    converted, failed = 0, 0
    for path in sorted(AGENT_SOURCE.glob("*.md")):
        try:
            name, text = convert_agent(path, catalog)
        except Exception as error:  # noqa: BLE001 - report and continue
            print(f"SKIP agent {path.name}: {error}", file=sys.stderr)
            failed += 1
            continue

        (target / f"{name}.md").write_text(text)
        converted += 1

    return converted, failed


# --- commands and skills ----------------------------------------------------


def build_commands():
    target = TARGET / "commands"
    shutil.rmtree(target, ignore_errors=True)
    target.mkdir(parents=True)

    seen = {}
    for source in COMMAND_SOURCES:
        for path in sorted(source.glob("*.md")):
            if not valid_name(path.stem):
                print(f"SKIP command {path.name}: invalid agens name", file=sys.stderr)
                continue
            if path.stem in seen:
                print(
                    f"SKIP command {path.name}: already taken from {seen[path.stem]}",
                    file=sys.stderr,
                )
                continue

            (target / path.name).write_text(rewrite(path.read_text()))
            seen[path.stem] = source.name

    return len(seen)


def normalize_manifest(path):
    """Move any preamble above the frontmatter below it.

    A few skills open with an HTML marker comment read by the harness sync
    tooling. Agens requires the first line of a manifest to be `---`, so the
    marker is relocated rather than dropped: it still means something to the
    tools that look for it.
    """
    if not path.exists():
        return

    text = path.read_text()
    if text.startswith("---\n"):
        return

    match = re.match(r"\A((?:<!--.*?-->\s*)+)(---\n.*?\n---\n)(.*)\Z", text, re.DOTALL)
    if not match:
        print(f"WARN {path}: preamble before frontmatter is not a comment", file=sys.stderr)
        return

    preamble, frontmatter, body = match.groups()
    path.write_text(f"{frontmatter}\n{preamble.strip()}\n{body.lstrip(chr(10))}")


def build_skills():
    target = TARGET / "skills"
    shutil.rmtree(target, ignore_errors=True)
    target.mkdir(parents=True)

    seen = set()
    for source in SKILL_SOURCES:
        for directory in sorted(path for path in source.iterdir() if path.is_dir()):
            if directory.name in seen:
                continue
            seen.add(directory.name)

            destination = target / directory.name
            shutil.copytree(directory, destination)
            normalize_manifest(destination / "SKILL.md")

            if directory.name in REWRITE_EXEMPT:
                continue

            for path in destination.rglob("*.md"):
                original = path.read_text()
                rewritten = rewrite(original)
                if rewritten != original:
                    path.write_text(rewritten)

    return len(seen)


def main():
    agents, failed = build_agents()
    commands = build_commands()
    skills = build_skills()

    # After build_skills, which clears the skills tree before repopulating it.
    build_shared_skill()
    build_orchestrator_skill()
    build_instructions()

    # `_shared` is replaced by the `sdd-shared` skill; two skills are synthesized.
    skills = skills - 1 + 2

    print("instructions: AGENTS.md")
    print(f"agents:       {agents} converted, {failed} skipped")
    print(f"commands:     {commands}")
    print(f"skills:       {skills} directories")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
