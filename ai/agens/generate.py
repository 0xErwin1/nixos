#!/usr/bin/env python3
"""Build the copied Agens harness from its semantic owners.

The generator stages every managed output before either comparing it or replacing
the copied tree. It never reads or writes the user-managed ``config.toml``.
"""

from __future__ import annotations

import argparse
import filecmp
import json
import re
import shutil
import sys
import tempfile
from dataclasses import dataclass
from pathlib import Path


NAME_PATTERN = re.compile(r"^[a-z0-9]([a-z0-9-]*[a-z0-9])?$")
CODEGRAPH_BLOCK = re.compile(
    r"\n?<!-- gentle-ai:codegraph-guidance -->.*?"
    r"<!-- /gentle-ai:codegraph-guidance -->\n?",
    re.DOTALL,
)
MODEL_ASSIGNMENTS = re.compile(r"\n## Model Assignments\n.*?(?=\n## |\Z)", re.DOTALL)
MODEL_ROUTING_SECTIONS = re.compile(
    r"\n#### (?:Visual-Aware Apply Split).*?(?=\n#### |\n### |\n## |\Z)",
    re.DOTALL,
)
SKILL_INVOCATION = re.compile(r"`([a-z0-9][a-z0-9-]*)` skill")
REQUIRED_CLIENT_SKILLS = ("sdd-testing-context", "setup-testing", "visual-diff")


@dataclass(frozen=True)
class SourceManifest:
    """The complete source ownership map for generated Agens assets."""

    global_policy: Path
    coordinator: Path
    workflow: Path
    agents: Path
    commands: tuple[Path, ...]
    skills: tuple[Path, ...]
    shared_references: tuple[Path, ...]


def managed_roots(ai_root: Path) -> tuple[str, ...]:
    """Load the shared inventory of generated Agens root paths."""
    roots = json.loads((ai_root / "agens/managed-roots.json").read_text())

    if not isinstance(roots, list) or any(not isinstance(root, str) or not root for root in roots):
        raise ValueError("invalid Agens managed-root inventory")
    if len(roots) != len(set(roots)):
        raise ValueError("duplicate Agens managed root")

    return tuple(roots)


def source_manifest(ai_root: Path) -> SourceManifest:
    """Return the intentional owner of each generated surface."""
    return SourceManifest(
        global_policy=ai_root / "shared/AGENTS.md",
        coordinator=ai_root / "opencode/ORCHESTRATOR.md",
        workflow=ai_root / "claude/skills/_shared/sdd-orchestrator-workflow.md",
        agents=ai_root / "claude/agents",
        commands=(ai_root / "claude/commands", ai_root / "command"),
        skills=(
            ai_root / "skills",
            *(ai_root / "claude/skills" / name for name in REQUIRED_CLIENT_SKILLS),
        ),
        shared_references=(
            ai_root / "skills/_shared",
            ai_root / "claude/skills/_shared",
        ),
    )


def rewrite_paths(text: str) -> str:
    """Translate complete Claude path clauses without corrupting Markdown spans."""
    clause_rewrites = (
        (
            r"(?:Read|read) (?:the )?(?:skill file at )?`~/\.claude/skills/([a-z0-9-]+)/SKILL\.md`(?: FIRST)?",
            r"Load the `\1` skill",
        ),
        (
            r"(?:Also )?(?:read|Read) shared conventions at `~/\.claude/skills/_shared/([a-z0-9-]+)\.md`",
            r"Also load the `\1` reference from the `sdd-shared` skill",
        ),
        (
            r"(?:Read|read) `~/\.claude/skills/_shared/sdd-orchestrator-workflow\.md`(?: first)?",
            "Load the `sdd-orchestrator` skill",
        ),
        (
            r"(?:Read|read) (?:the )?agent file at `~/\.claude/agents/[a-z0-9-]+\.md`(?: FIRST)?",
            "Load the `sdd-orchestrator` skill",
        ),
    )

    for pattern, replacement in clause_rewrites:
        text = re.sub(pattern, replacement, text)

    path_rewrites = (
        (r"`~/\.claude/skills/_shared/([a-z0-9-]+)\.md`", r"the `\1` reference of the `sdd-shared` skill"),
        (r"`~/\.claude/skills/([a-z0-9-]+)/SKILL\.md`", r"the `\1` skill"),
        (r"`~/\.claude/CLAUDE\.md`", "the `sdd-orchestrator` skill"),
        (r"`~/\.claude/(?:agents|commands)/[a-z0-9-]+\.md`", "the `sdd-orchestrator` skill"),
        (r"~/\.claude", "~/.config/agens"),
    )

    for pattern, replacement in path_rewrites:
        text = re.sub(pattern, replacement, text)

    return text


def strip_codegraph(text: str) -> str:
    return CODEGRAPH_BLOCK.sub("\n", text).strip() + "\n"


def normalize_markdown(text: str) -> str:
    """Emit stable Markdown with no trailing whitespace and one final newline."""
    return "\n".join(line.rstrip() for line in text.splitlines()).strip() + "\n"


def adapt_choice_transport(text: str) -> str:
    """Replace Claude-only questioning with Agens's blocking chat contract."""
    has_claude_transport = "AskUserQuestion" in text
    text = text.replace("AskUserQuestion", "grouped choice prompt")
    text = text.replace("Use the built-in `grouped choice prompt` tool", "Use Agens choice transport")
    text = text.replace("single `grouped choice prompt` call", "single grouped choice prompt")
    text = text.replace("three separate `grouped choice prompt` tool calls", "three separate choice prompts")

    if not has_claude_transport:
        return text

    return text.rstrip() + """

## Agens choice transport

Use one grouped blocking choice prompt when the Agens runtime exposes a choice
mechanism that can represent every option. Otherwise present the complete
question, options, default, consequence, and answer syntax in chat, block for
the reply, and validate it before continuing. Never infer a missing choice.
"""


def adapt_workflow(text: str) -> str:
    """Adapt all generated Markdown away from unsupported Claude mechanics."""
    text = MODEL_ASSIGNMENTS.sub("\n", text)
    text = MODEL_ROUTING_SECTIONS.sub("\n", text)
    text = re.sub(
        r"\n\*\*Pre-flight before every Agent call.*?(?=\n### |\n## |\Z)",
        "\n",
        text,
        flags=re.DOTALL,
    )
    text = re.sub(
        r"Each named agent uses its configured model from the Model Assignments table\.",
        "Each named agent uses the runtime's configured model.",
        text,
    )
    text = re.sub(
        r"The model is controlled by.*?(?=\n\n|\Z)",
        "Model selection is controlled by the Agens runtime configuration.",
        text,
        flags=re.DOTALL,
    )
    return normalize_markdown(adapt_choice_transport(strip_codegraph(rewrite_paths(text))))


def split_frontmatter(text: str) -> tuple[str, str]:
    if not text.startswith("---\n"):
        raise ValueError("missing frontmatter")

    end = text.find("\n---", 3)
    if end == -1:
        raise ValueError("unterminated frontmatter")

    return text[4:end], text[end + 4 :].lstrip("\n")


def parse_frontmatter(block: str) -> dict[str, str]:
    fields: dict[str, str] = {}
    key: str | None = None

    for line in block.splitlines():
        match = re.match(r"^([A-Za-z_-]+):\s?(.*)$", line)
        if match and not line.startswith(" "):
            key = match.group(1)
            fields[key] = match.group(2)
        elif key is not None:
            fields[key] += "\n" + line

    return fields


def description(raw: str) -> str:
    text = raw.strip()
    for marker in ("<example>", "\n\n", "Examples:", "Example:"):
        position = text.find(marker)
        if position > 0:
            text = text[:position]

    text = " ".join(text.split()).strip(' "')
    if not text:
        raise ValueError("description is empty")
    return text[:1024].rstrip(" ,;:.")


def permissions(tools: str) -> list[str]:
    if not tools or tools.strip() in {"*", "All tools"}:
        return []

    allowed = {tool.strip() for tool in tools.split(",")}
    result = []
    if not allowed & {"Write", "Edit", "NotebookEdit", "MultiEdit"}:
        result.append("deny write")
    if not allowed & {"Bash", "BashOutput", "KillShell"}:
        result.append("deny bash")
    return result


def available_skills(manifest: SourceManifest) -> set[str]:
    """Return catalog names that an Agens subagent may preload by name."""
    return {
        path.name
        for path in owned_skill_sources(manifest)
        if path.is_dir() and path.joinpath("SKILL.md").is_file()
    } | {"sdd-shared", "sdd-orchestrator"}


def owned_skill_sources(manifest: SourceManifest) -> tuple[Path, ...]:
    """Expand shared roots and preserve explicitly owned client skill packages."""
    sources: list[Path] = []
    for root in manifest.skills:
        if root.name in REQUIRED_CLIENT_SKILLS:
            sources.append(root)
        elif root.is_dir():
            sources.extend(sorted(root.iterdir()))
    return tuple(sources)


def expected_output_names(manifest: SourceManifest) -> dict[str, set[str]]:
    """Return the exact generated family names from the semantic manifest."""
    agents = {source.name for source in manifest.agents.glob("*.md")}
    commands = {
        source.name
        for directory in manifest.commands
        for source in directory.glob("*.md")
    }
    skills = {
        source.name
        for source in owned_skill_sources(manifest)
        if source.is_dir() and source.name != "_shared" and source.joinpath("SKILL.md").is_file()
    } | {"sdd-shared", "sdd-orchestrator"}

    if len(commands) != sum(len(list(directory.glob("*.md"))) for directory in manifest.commands):
        raise ValueError("duplicate Agens command name in semantic manifest")

    return {"agents": agents, "commands": commands, "skills": skills}


def declared_skills(body: str, catalog: set[str]) -> list[str]:
    """Preserve only real skill-by-name preloads in first-mention order."""
    result: list[str] = []
    for name in SKILL_INVOCATION.findall(body):
        if name in catalog and name not in result and name != "sdd-orchestrator":
            result.append(name)
    return result


def copy_agents(stage: Path, manifest: SourceManifest) -> None:
    target = stage / "agents"
    target.mkdir()
    catalog = available_skills(manifest)

    for source in sorted(manifest.agents.glob("*.md")):
        frontmatter, body = split_frontmatter(source.read_text())
        fields = parse_frontmatter(frontmatter)
        name = fields.get("name", source.stem).strip()

        if name != source.stem or not NAME_PATTERN.fullmatch(name):
            raise ValueError(f"invalid Agens agent name: {source.name}")

        lines = [
            "---",
            f"name: {name}",
            f"description: {json.dumps(description(fields.get('description', '')))}",
            "mode: subagent",
        ]
        rules = permissions(fields.get("tools", ""))
        skills = declared_skills(body, catalog)
        if skills:
            lines.extend(["skills:", *(f"  - {skill}" for skill in skills)])
        if rules:
            lines.extend(["permissions:", *(f"  - {rule}" for rule in rules)])

        lines.extend(["---", "", adapt_workflow(body).rstrip(), ""])
        (target / source.name).write_text("\n".join(lines))


def copy_commands(stage: Path, manifest: SourceManifest) -> None:
    target = stage / "commands"
    target.mkdir()
    names: set[str] = set()

    for directory in manifest.commands:
        for source in sorted(directory.glob("*.md")):
            if not NAME_PATTERN.fullmatch(source.stem):
                raise ValueError(f"invalid Agens command name: {source.name}")
            if source.stem in names:
                raise ValueError(f"duplicate Agens command: {source.stem}")

            names.add(source.stem)
            (target / source.name).write_text(adapt_workflow(source.read_text()))


def normalize_manifest(path: Path) -> None:
    text = path.read_text()
    if text.startswith("---\n"):
        return

    match = re.match(r"\A((?:<!--.*?-->\s*)+)(---\n.*?\n---\n)(.*)\Z", text, re.DOTALL)
    if not match:
        raise ValueError(f"manifest does not start with frontmatter: {path}")

    preamble, frontmatter, body = match.groups()
    path.write_text(f"{frontmatter}\n{preamble.strip()}\n{body.lstrip()}")


def copy_skills(stage: Path, manifest: SourceManifest) -> None:
    target = stage / "skills"
    target.mkdir()

    for source in owned_skill_sources(manifest):
        if (
            not source.is_dir()
            or source.name == "_shared"
            or not source.joinpath("SKILL.md").is_file()
        ):
            continue

        destination = target / source.name
        if destination.exists():
            raise ValueError(f"duplicate Agens skill: {source.name}")
        shutil.copytree(source, destination)
        normalize_manifest(destination / "SKILL.md")

        for markdown in destination.rglob("*.md"):
            markdown.write_text(adapt_workflow(markdown.read_text()))

    shared = target / "sdd-shared"
    references = shared / "references"
    references.mkdir(parents=True)
    names: set[str] = set()
    for source in manifest.shared_references:
        for document in sorted(source.glob("*.md")):
            if (
                document.name == "README.md"
                or document == manifest.workflow
                or document.name in names
            ):
                continue
            names.add(document.name)
            references.joinpath(document.name).write_text(
                adapt_workflow(document.read_text())
            )

    shared.joinpath("SKILL.md").write_text(
        "---\n"
        "name: sdd-shared\n"
        'description: "Shared SDD contracts and conventions."\n'
        "---\n\n"
        "Load a named reference through this skill rather than by filesystem path.\n"
    )


def build_instructions(stage: Path, manifest: SourceManifest) -> None:
    global_policy = normalize_markdown(manifest.global_policy.read_text()).rstrip()
    coordinator = adapt_workflow(manifest.coordinator.read_text())
    coordinator = coordinator.replace(
        "Read `~/.config/opencode/skills/_shared/sdd-orchestrator-workflow.md`",
        "Load the `sdd-orchestrator` skill",
    )

    stage.joinpath("AGENTS.md").write_text(
        f"{global_policy}\n\n## Agens SDD coordination\n\n{coordinator}"
    )


def build_orchestrator_skill(stage: Path, manifest: SourceManifest) -> None:
    directory = stage / "skills/sdd-orchestrator"
    directory.mkdir(parents=True)
    workflow = adapt_workflow(manifest.workflow.read_text())
    directory.joinpath("SKILL.md").write_text(
        "---\n"
        "name: sdd-orchestrator\n"
        'description: "Lazy SDD workflow and phase mechanics for Agens."\n'
        "---\n\n"
        f"{workflow.lstrip()}"
    )


def stage_outputs(ai_root: Path, stage: Path) -> None:
    manifest = source_manifest(ai_root)
    expected_output_names(manifest)
    build_instructions(stage, manifest)
    copy_agents(stage, manifest)
    copy_commands(stage, manifest)
    copy_skills(stage, manifest)
    build_orchestrator_skill(stage, manifest)


def files_under(root: Path) -> set[Path]:
    return {path.relative_to(root) for path in root.rglob("*") if path.is_file()}


def compare_outputs(stage: Path, target: Path, roots: tuple[str, ...]) -> list[str]:
    differences: list[str] = []
    for root in roots:
        staged = stage / root
        current = target / root
        staged_files = files_under(staged) if staged.is_dir() else {Path(root)}
        current_files = files_under(current) if current.is_dir() else ({Path(root)} if current.is_file() else set())

        for relative in sorted(staged_files - current_files):
            differences.append(f"missing {root}/{relative}" if staged.is_dir() else f"missing {root}")
        for relative in sorted(current_files - staged_files):
            differences.append(f"extra {root}/{relative}" if staged.is_dir() else f"extra {root}")
        for relative in sorted(staged_files & current_files):
            staged_file = staged / relative if staged.is_dir() else staged
            current_file = current / relative if current.is_dir() else current
            if not filecmp.cmp(staged_file, current_file, shallow=False):
                differences.append(f"changed {root}/{relative}" if staged.is_dir() else f"changed {root}")
    return differences


def install_outputs(stage: Path, target: Path, roots: tuple[str, ...]) -> None:
    for name in roots:
        destination = target / name
        if destination.is_dir():
            shutil.rmtree(destination)
        elif destination.exists():
            destination.unlink()
        shutil.move(str(stage / name), str(destination))


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="compare generated outputs without writing")
    parser.add_argument("--root", type=Path, help="AI source root; defaults to this script's parent")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    ai_root = (args.root or Path(__file__).resolve().parent.parent).resolve()
    target = ai_root / "agens"
    roots = managed_roots(ai_root)

    with tempfile.TemporaryDirectory(prefix="agens-generation-") as temporary:
        stage = Path(temporary) / "agens"
        stage.mkdir()
        stage_outputs(ai_root, stage)

        if args.check:
            differences = compare_outputs(stage, target, roots)
            if differences:
                print("Agens generated outputs differ:", file=sys.stderr)
                print("\n".join(f"- {item}" for item in differences), file=sys.stderr)
                return 1
            return 0

        install_outputs(stage, target, roots)
        return 0


if __name__ == "__main__":
    sys.exit(main())
