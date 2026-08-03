#!/usr/bin/env python3
"""Golden tests for deterministic, sandbox-only Agens harness generation."""

from __future__ import annotations

import hashlib
import importlib.util
import re
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


REPOSITORY = Path(__file__).resolve().parent.parent
CANONICAL_AI = REPOSITORY / "ai"
REQUIRED_CLIENT_SKILLS = {"sdd-testing-context", "setup-testing", "visual-diff"}
UNSUPPORTED_CLAUDE_SYNTAX = (
    "AskUserQuestion",
    "## Model Assignments",
    "model alias",
    "via the `model` parameter",
    'model: "',
)


def digest_tree(root: Path) -> dict[str, str]:
    return {
        str(path.relative_to(root)): hashlib.sha256(path.read_bytes()).hexdigest()
        for path in sorted(root.rglob("*"))
        if path.is_file()
    }


def managed_markdown(root: Path, roots: tuple[str, ...]) -> list[Path]:
    paths: list[Path] = []
    for name in roots:
        target = root / name
        if target.is_file() and target.suffix == ".md":
            paths.append(target)
        elif target.is_dir():
            paths.extend(target.rglob("*.md"))
    return sorted(paths)


def semantic_skill_references(text: str) -> set[str]:
    loads = re.findall(r"\b[Ll]oad (?:the )?`([a-z0-9][a-z0-9-]*)` skill", text)
    references = re.findall(r"`([a-z0-9][a-z0-9-]*)` reference from the `sdd-shared` skill", text)
    return set(loads) | set(references)


class AgensGenerationTest(unittest.TestCase):
    def setUp(self) -> None:
        self.canonical_hashes = digest_tree(CANONICAL_AI / "agens")
        self.temporary = tempfile.TemporaryDirectory(prefix="agens-generation-test-")
        self.sandbox = Path(self.temporary.name) / "ai"
        shutil.copytree(CANONICAL_AI, self.sandbox)
        self.generator = self.sandbox / "agens/generate.py"
        spec = importlib.util.spec_from_file_location("agens_generation", self.generator)
        self.generator_module = importlib.util.module_from_spec(spec)
        assert spec.loader is not None
        sys.modules[spec.name] = self.generator_module
        spec.loader.exec_module(self.generator_module)

    def tearDown(self) -> None:
        self.temporary.cleanup()
        self.assertEqual(self.canonical_hashes, digest_tree(CANONICAL_AI / "agens"))

    def run_generator(self, *arguments: str, expected: int = 0) -> subprocess.CompletedProcess[str]:
        result = subprocess.run(
            ["python3", self.generator, "--root", self.sandbox, *arguments],
            check=False,
            capture_output=True,
            text=True,
        )
        self.assertEqual(expected, result.returncode, result.stderr)
        return result

    def test_generation_is_exact_idempotent_and_adapted(self) -> None:
        protected_config = hashlib.sha256((self.sandbox / "agens/config.toml").read_bytes()).hexdigest()
        self.run_generator()
        first = digest_tree(self.sandbox / "agens")
        self.run_generator("--check")
        self.run_generator()
        self.assertEqual(first, digest_tree(self.sandbox / "agens"))
        self.assertEqual(
            protected_config,
            hashlib.sha256((self.sandbox / "agens/config.toml").read_bytes()).hexdigest(),
        )

        agents = (self.sandbox / "agens/AGENTS.md").read_text()
        workflow = (self.sandbox / "agens/skills/sdd-orchestrator/SKILL.md").read_text()
        self.assertIn("## Agens SDD coordination", agents)
        self.assertEqual(1, agents.count("## CodeGraph"))
        self.assertIn("## Agens choice transport", workflow)
        self.assertNotIn("Codex", (self.sandbox / "agens/generate.py").read_text())

        for agent in (self.sandbox / "agens/agents").glob("*.md"):
            frontmatter = agent.read_text().split("---", 2)[1]
            self.assertNotIn("model:", frontmatter)
            for skill in frontmatter.split("skills:\n")[-1].split("permissions:")[0].splitlines():
                if skill.startswith("  - "):
                    self.assertTrue((self.sandbox / "agens/skills" / skill[4:]).is_dir())

        manifest = self.generator_module.source_manifest(self.sandbox)
        managed_roots = self.generator_module.managed_roots(self.sandbox)
        self.assertEqual(("AGENTS.md", "agents", "commands", "skills"), managed_roots)
        expected_outputs = self.generator_module.expected_output_names(manifest)

        expected_agents = expected_outputs["agents"]
        actual_agents = {path.name for path in (self.sandbox / "agens/agents").glob("*.md")}
        self.assertEqual(expected_agents, actual_agents)

        expected_commands = expected_outputs["commands"]
        actual_commands = {path.name for path in (self.sandbox / "agens/commands").glob("*.md")}
        self.assertEqual(expected_commands, actual_commands)

        expected_skills = expected_outputs["skills"]
        actual_skills = {path.name for path in (self.sandbox / "agens/skills").iterdir() if path.is_dir()}
        self.assertEqual(expected_skills, actual_skills)
        self.assertTrue(REQUIRED_CLIENT_SKILLS <= actual_skills)

        shared_references = self.sandbox / "agens/skills/sdd-shared/references"
        self.assertFalse((shared_references / "sdd-orchestrator-workflow.md").exists())
        self.assertFalse(
            (self.sandbox / "agens/skills/skill-improver/skill-improver").exists()
        )

        markdown = managed_markdown(self.sandbox / "agens", managed_roots)
        self.assertTrue(markdown)
        for path in markdown:
            text = path.read_text()
            relative = path.relative_to(self.sandbox / "agens")

            self.assertIsNone(re.search(r"the `[^`]+``", text), relative)
            self.assertFalse(any(line.rstrip() != line for line in text.splitlines()), relative)
            self.assertFalse(any(token in text for token in UNSUPPORTED_CLAUDE_SYNTAX), relative)

            for skill in semantic_skill_references(text):
                package = self.sandbox / "agens/skills" / skill
                reference = self.sandbox / "agens/skills/sdd-shared/references" / f"{skill}.md"
                self.assertTrue(package.is_dir() or reference.is_file(), f"{relative}: {skill}")

        all_text = "\n".join(path.read_text() for path in markdown)
        self.assertEqual(1, all_text.count("<!-- gentle-ai:codegraph-guidance -->"))
        self.assertEqual(1, all_text.count("<!-- /gentle-ai:codegraph-guidance -->"))
        self.assertNotIn("review-refuter.md", {path.name for path in (self.sandbox / "agens/agents").glob("*.md")})

    def test_check_detects_drift_and_generation_removes_stale_files(self) -> None:
        self.run_generator()
        stale = self.sandbox / "agens/skills/stale/SKILL.md"
        stale.parent.mkdir()
        stale.write_text("stale\n")
        self.run_generator("--check", expected=1)
        self.run_generator()
        self.assertFalse(stale.exists())

        generated = self.sandbox / "agens/AGENTS.md"
        before = generated.read_text()
        generated.write_text(before + "drift\n")
        self.run_generator("--check", expected=1)
        self.assertEqual(before + "drift\n", generated.read_text())


if __name__ == "__main__":
    unittest.main()
