"""Fixture checks for the Claude-only ClickUp activation cleanup."""

import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import tomllib
import unittest


SCRIPT = Path(os.environ.get("RETIRE_CLICKUP_SCRIPT", Path(__file__).resolve().parents[1] / "ai/support/retire-clickup-mcp.py"))
CODEX = shutil.which("codex")


@unittest.skipUnless(CODEX, "Codex CLI is needed to verify its own TOML writer")
class RetireClickUpTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.agent = self.root / "agent"
        self.agent.mkdir()
        self.codex = self.root / "codex"
        self.codex.mkdir()
        self.native = self.agent / "mcp.json"
        self.legacy = self.agent / "mcp-adapter.json"
        self.config = self.codex / "config.toml"
        self.native.write_text(json.dumps({"mcpServers": {"clickup": {"command": "npx"}, "keep": {"url": "https://example.test"}}, "other": 7}))
        self.legacy.write_text(json.dumps({"mcpServers": {"clickup": {"command": "npx"}, "legacy": {"command": "echo"}}}))
        self.config.write_text('[mcp_servers.clickup]\ncommand = "npx"\n\n[mcp_servers.keep]\ncommand = "echo"\n')
        for path in (self.native, self.legacy, self.config):
            path.chmod(0o600)

    def run_cleanup(self):
        return subprocess.run(
            [sys.executable, str(SCRIPT), "--agent-dir", str(self.agent), "--codex-home", str(self.codex), "--codex-bin", CODEX],
            capture_output=True,
            text=True,
            env={**os.environ, "CODEX_HOME": str(self.codex)},
        )

    def test_removes_only_clickup_and_preserves_modes(self):
        result = self.run_cleanup()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(self.native.read_text()), {"mcpServers": {"keep": {"url": "https://example.test"}}, "other": 7})
        self.assertEqual(json.loads(self.legacy.read_text()), {"mcpServers": {"legacy": {"command": "echo"}}})
        self.assertEqual(tomllib.loads(self.config.read_text())["mcp_servers"], {"keep": {"command": "echo"}})
        for path in (self.native, self.legacy, self.config):
            self.assertEqual(path.stat().st_mode & 0o777, 0o600)
        self.assertEqual(self.run_cleanup().returncode, 0, "cleanup must be idempotent")

    def test_malformed_json_aborts_before_any_write(self):
        self.legacy.write_text("{malformed")
        before = (self.native.read_bytes(), self.legacy.read_bytes(), self.config.read_bytes())
        result = self.run_cleanup()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("malformed", result.stderr.lower())
        self.assertEqual(before, (self.native.read_bytes(), self.legacy.read_bytes(), self.config.read_bytes()))

    def test_malformed_native_or_codex_aborts_before_any_write(self):
        for path, malformed in ((self.native, b""), (self.config, b"[mcp_servers.clickup\n")):
            with self.subTest(path=path.name):
                original = path.read_bytes()
                path.write_bytes(malformed)
                before = (self.native.read_bytes(), self.legacy.read_bytes(), self.config.read_bytes())
                result = self.run_cleanup()
                self.assertNotEqual(result.returncode, 0)
                self.assertIn("malformed", result.stderr.lower())
                self.assertEqual(before, (self.native.read_bytes(), self.legacy.read_bytes(), self.config.read_bytes()))
                path.write_bytes(original)

    def test_codex_failure_leaves_pi_files_unchanged(self):
        failing_codex = self.root / "failing-codex"
        failing_codex.write_text("#!/bin/sh\nexit 17\n")
        failing_codex.chmod(0o700)
        before = (self.native.read_bytes(), self.legacy.read_bytes(), self.config.read_bytes())
        result = subprocess.run(
            [sys.executable, str(SCRIPT), "--agent-dir", str(self.agent), "--codex-home", str(self.codex), "--codex-bin", str(failing_codex)],
            capture_output=True,
            text=True,
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Codex could not retire ClickUp", result.stderr)
        self.assertEqual(before, (self.native.read_bytes(), self.legacy.read_bytes(), self.config.read_bytes()))

    def test_symlink_destination_is_rejected(self):
        target = self.root / "unrelated.json"
        target.write_text('{"mcpServers":{"clickup":{}}}')
        self.native.unlink()
        self.native.symlink_to(target)
        before = (target.read_bytes(), self.legacy.read_bytes(), self.config.read_bytes())
        result = self.run_cleanup()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("symlink", result.stderr.lower())
        self.assertEqual(before, (target.read_bytes(), self.legacy.read_bytes(), self.config.read_bytes()))


if __name__ == "__main__":
    unittest.main()
