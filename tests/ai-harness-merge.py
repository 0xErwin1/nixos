#!/usr/bin/env python3
"""Focused regression tests for additive Agens TOML MCP merging."""

import importlib.util
import pathlib
import tempfile
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[1]
HELPER_PATH = ROOT / "home-manager/global/ai-harness-merge.py"
spec = importlib.util.spec_from_file_location("ai_harness_merge", HELPER_PATH)
merge = importlib.util.module_from_spec(spec)
spec.loader.exec_module(merge)


class AdditiveAgensMergeTests(unittest.TestCase):
    fragment = """[mcp]
enabled = false

[permissions]
allow = ["canonical"]

[mcp.aws]
command = "canonical-aws"

[mcp.atlas]
command = "canonical-atlas"

[mcp."quoted server"]
command = "canonical-quoted"
"""

    def merge(self, existing):
        with tempfile.TemporaryDirectory() as directory:
            target = pathlib.Path(directory) / "config.toml"
            target.write_text(existing, encoding="utf-8")
            merge.merge_toml_mcp_permissions_additive(self.fragment, str(target))
            once = target.read_text(encoding="utf-8")
            merge.merge_toml_mcp_permissions_additive(self.fragment, str(target))
            twice = target.read_text(encoding="utf-8")
        self.assertEqual(twice, once)
        return once

    def test_preserves_existing_tables_and_adds_only_missing_mcps(self):
        existing = """# User-owned preamble
provider = "local"
model = "custom-model"

[permissions]
allow = ["user-rule"]
# User permission comment

[mcp.aws]
command = "user-aws"
args = ["--keep"]

[mcp."quoted server"]
command = "user-quoted"

[mcp.custom]
command = "custom-server"

[mcp_defaults]
timeout = 30

[other]
value = "unchanged"
"""
        rendered = self.merge(existing)

        self.assertTrue(rendered.startswith(existing))
        self.assertIn('allow = ["user-rule"]\n# User permission comment', rendered)
        self.assertIn('[mcp.aws]\ncommand = "user-aws"\nargs = ["--keep"]', rendered)
        self.assertIn('[mcp."quoted server"]\ncommand = "user-quoted"', rendered)
        self.assertIn('[mcp.custom]\ncommand = "custom-server"', rendered)
        self.assertIn('[mcp_defaults]\ntimeout = 30', rendered)
        self.assertIn('[other]\nvalue = "unchanged"', rendered)
        self.assertEqual(rendered.count("[mcp]"), 1)
        self.assertEqual(rendered.count("[permissions]"), 1)
        self.assertEqual(rendered.count("[mcp.aws]"), 1)
        self.assertEqual(rendered.count('[mcp."quoted server"]'), 1)
        self.assertEqual(rendered.count("[mcp.atlas]"), 1)

    def test_adds_permissions_when_absent_and_preserves_mcp_parent(self):
        existing = """provider = "local"

[mcp]
enabled = true
"""
        rendered = self.merge(existing)

        self.assertTrue(rendered.startswith(existing))
        self.assertIn('[permissions]\nallow = ["canonical"]', rendered)
        self.assertEqual(rendered.count("[mcp]"), 1)
        self.assertEqual(rendered.count("[mcp.aws]"), 1)
        self.assertEqual(rendered.count("[mcp.atlas]"), 1)


if __name__ == "__main__":
    unittest.main()
