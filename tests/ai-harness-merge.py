#!/usr/bin/env python3
"""Focused regression tests for managed Agens TOML MCP merging."""

import importlib.util
import pathlib
import tempfile
import tomllib
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[1]
HELPER_PATH = ROOT / "home-manager/global/ai-harness-merge.py"
spec = importlib.util.spec_from_file_location("ai_harness_merge", HELPER_PATH)
merge = importlib.util.module_from_spec(spec)
spec.loader.exec_module(merge)


class ManagedAgensMergeTests(unittest.TestCase):
    fragment = """[permissions]
allow = ["canonical"]

[mcp.aws]
command = "canonical-aws"

[mcp.atlas]
command = "canonical-atlas"

[mcp."quoted server"]
command = "canonical-quoted"
"""

    def merge(self, existing, fragment=None, twice=True):
        with tempfile.TemporaryDirectory() as directory:
            target = pathlib.Path(directory) / "config.toml"
            target.write_bytes(existing.encode())
            merge.merge_toml_mcp_permissions(fragment or self.fragment, str(target))
            once = target.read_bytes().decode()
            tomllib.loads(once)
            if twice:
                merge.merge_toml_mcp_permissions(fragment or self.fragment, str(target))
                repeated = target.read_bytes().decode()
                self.assertEqual(repeated, once)
        return once

    def test_migrates_canonical_tables_and_preserves_custom_mcp(self):
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

        self.assertTrue(rendered.startswith('# User-owned preamble\nprovider = "local"'))
        self.assertNotIn('allow = ["user-rule"]', rendered)
        self.assertNotIn('command = "user-aws"', rendered)
        self.assertNotIn('command = "user-quoted"', rendered)
        self.assertIn('[mcp.custom]\ncommand = "custom-server"', rendered)
        self.assertIn('[mcp_defaults]\ntimeout = 30', rendered)
        self.assertIn('[other]\nvalue = "unchanged"', rendered)
        self.assertEqual(rendered.count("[permissions]"), 1)
        self.assertEqual(rendered.count("[mcp.aws]"), 1)
        self.assertEqual(rendered.count('[mcp."quoted server"]'), 1)
        self.assertEqual(rendered.count("[mcp.atlas]"), 1)
        self.assertEqual(rendered.count(merge.AGENS_MANAGED_BEGIN), 1)
        self.assertEqual(rendered.count(merge.AGENS_MANAGED_END), 1)

    def test_migration_removes_descendants_and_preserves_trailing_trivia(self):
        existing = """provider = "local"

[mcp.aws]
command = "legacy-aws"

[mcp.aws.env]
region = "legacy"

[[mcp.aws.routes]]
name = "legacy-route"

# Keep this comment outside the removed canonical tables.

[mcp.custom]
command = "custom-server"
"""

        rendered = self.merge(existing)

        self.assertNotIn("legacy-aws", rendered)
        self.assertNotIn('region = "legacy"', rendered)
        self.assertNotIn("mcp.aws.routes", rendered)
        self.assertIn(
            "# Keep this comment outside the removed canonical tables.\n\n"
            "[mcp.custom]",
            rendered,
        )
        self.assertIn('[mcp.custom]\ncommand = "custom-server"', rendered)

    def test_replaces_only_the_marked_block_and_preserves_exterior_bytes(self):
        old_fragment = self.fragment.replace("canonical-aws", "old-aws")
        managed = merge.render_agens_managed_block(
            merge.canonical_agens_blocks(old_fragment)[1]
        )
        prefix = "# User bytes before\r\nprovider = \"local\"\r\n\r\n"
        suffix = "# User bytes after\r\n[runtime]\r\ncache = true\r\n"
        existing = prefix + managed + suffix

        rendered = self.merge(existing)

        self.assertTrue(rendered.startswith(prefix))
        self.assertTrue(rendered.endswith(suffix))
        self.assertIn('command = "canonical-aws"', rendered)
        self.assertNotIn('command = "old-aws"', rendered)

    def test_migration_preserves_parent_mcp_and_runtime_tables(self):
        existing = """provider = "local"

[mcp]
enabled = true

[runtime]
cache = true
"""
        rendered = self.merge(existing)

        self.assertIn('provider = "local"', rendered)
        self.assertIn('[mcp]\nenabled = true', rendered)
        self.assertIn('[runtime]\ncache = true', rendered)
        self.assertIn('[permissions]\nallow = ["canonical"]', rendered)
        self.assertEqual(rendered.count("[mcp]"), 1)
        self.assertEqual(rendered.count("[mcp.aws]"), 1)
        self.assertEqual(rendered.count("[mcp.atlas]"), 1)

    def test_multiline_strings_hide_false_headers_and_markers(self):
        existing = (
            'provider = "local"\n'
            'basic = """\n'
            '[mcp.aws]\n'
            f'{merge.AGENS_MANAGED_BEGIN}\n'
            f'{merge.AGENS_MANAGED_END}\n'
            '"""\n'
            "literal = '''\n"
            '[permissions]\n'
            f'{merge.AGENS_MANAGED_BEGIN}\n'
            f'{merge.AGENS_MANAGED_END}\n'
            "'''\n"
            f'marker_text = "{merge.AGENS_MANAGED_BEGIN}"\n'
            f'# Documentation mentions {merge.AGENS_MANAGED_END}\n'
            '\n[mcp.custom]\n'
            'command = "custom-server"\n'
        )

        rendered = self.merge(existing)
        parsed = tomllib.loads(rendered)

        self.assertIn("[mcp.aws]", parsed["basic"])
        self.assertIn("[permissions]", parsed["literal"])
        self.assertEqual(parsed["marker_text"], merge.AGENS_MANAGED_BEGIN)
        self.assertEqual(parsed["mcp"]["custom"]["command"], "custom-server")
        self.assertEqual(rendered.count(merge.AGENS_MANAGED_BEGIN), 4)
        self.assertEqual(rendered.count(merge.AGENS_MANAGED_END), 4)

    def test_idempotence_after_unmarked_migration(self):
        rendered = self.merge('provider = "local"\n')

        self.assertEqual(rendered.count(merge.AGENS_MANAGED_BEGIN), 1)
        self.assertEqual(rendered.count(merge.AGENS_MANAGED_END), 1)

    def test_rejects_corrupt_or_unbalanced_markers(self):
        corrupt_targets = (
            merge.AGENS_MANAGED_BEGIN + "\n[permissions]\nallow = []\n",
            merge.AGENS_MANAGED_END + "\n",
            merge.AGENS_MANAGED_END + "\n" + merge.AGENS_MANAGED_BEGIN + "\n",
            (
                merge.AGENS_MANAGED_BEGIN
                + "\n"
                + merge.AGENS_MANAGED_BEGIN
                + "\n"
                + merge.AGENS_MANAGED_END
                + "\n"
            ),
            (
                merge.AGENS_MANAGED_BEGIN
                + "\n"
                + merge.AGENS_MANAGED_END
                + "\n"
                + merge.AGENS_MANAGED_END
                + "\n"
            ),
        )

        for existing in corrupt_targets:
            with self.subTest(existing=existing):
                with self.assertRaisesRegex(ValueError, "corrupt Agens managed markers"):
                    self.merge(existing, twice=False)


if __name__ == "__main__":
    unittest.main()
