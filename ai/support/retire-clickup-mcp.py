#!/usr/bin/env python3
"""Retire only persisted ClickUp MCP entries outside Claude at activation.

Pi's legacy config is checked as well as its native config: the native-MCP
migration can otherwise copy the retired entry back on a later activation.
No live files are touched until all participating configs have been parsed.
"""

import argparse
import json
import os
from pathlib import Path
import stat
import subprocess
import sys
import tempfile
import tomllib


def regular_bytes(path: Path) -> tuple[bytes, int] | None:
    try:
        info = path.lstat()
    except FileNotFoundError:
        return None
    if stat.S_ISLNK(info.st_mode):
        raise ValueError(f"{path}: symlink destination refused")
    if not stat.S_ISREG(info.st_mode):
        raise ValueError(f"{path}: expected a regular file")
    return path.read_bytes(), stat.S_IMODE(info.st_mode)


def plan_pi_file(path: Path) -> tuple[bytes, int] | None:
    existing = regular_bytes(path)
    if existing is None:
        return None
    raw, mode = existing
    try:
        document = json.loads(raw)
    except (ValueError, UnicodeDecodeError) as error:
        raise ValueError(f"{path}: malformed JSON: {error}") from error
    if not isinstance(document, dict):
        raise ValueError(f"{path}: expected a JSON object")
    servers = document.get("mcpServers", {})
    if not isinstance(servers, dict):
        raise ValueError(f"{path}: mcpServers must be a JSON object")
    if "clickup" not in servers:
        return None
    del servers["clickup"]
    document["mcpServers"] = servers
    return (json.dumps(document, indent=2, ensure_ascii=False) + "\n").encode(), mode


def codex_has_clickup(path: Path) -> bool:
    existing = regular_bytes(path)
    if existing is None:
        return False
    try:
        document = tomllib.loads(existing[0].decode())
    except (ValueError, UnicodeDecodeError) as error:
        raise ValueError(f"{path}: malformed TOML: {error}") from error
    servers = document.get("mcp_servers", {})
    if not isinstance(servers, dict):
        raise ValueError(f"{path}: mcp_servers must be a TOML table")
    return "clickup" in servers


def replace_atomic(path: Path, content: bytes, mode: int) -> None:
    descriptor, temporary = tempfile.mkstemp(prefix=f".{path.name}.clickup-", dir=path.parent)
    try:
        with os.fdopen(descriptor, "wb") as stream:
            os.fchmod(stream.fileno(), mode)
            stream.write(content)
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(temporary, path)
        directory = os.open(path.parent, os.O_RDONLY | os.O_DIRECTORY)
        try:
            os.fsync(directory)
        finally:
            os.close(directory)
    finally:
        if os.path.lexists(temporary):
            os.unlink(temporary)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--agent-dir", type=Path, required=True)
    parser.add_argument("--codex-home", type=Path, required=True)
    parser.add_argument("--codex-bin", required=True)
    args = parser.parse_args()
    if not args.agent_dir.is_absolute() or not args.codex_home.is_absolute():
        parser.error("config directories must be absolute")

    try:
        pi_paths = (args.agent_dir / "mcp.json", args.agent_dir / "mcp-adapter.json")
        planned = [(path, update) for path in pi_paths if (update := plan_pi_file(path)) is not None]
        codex_config = args.codex_home / "config.toml"
        if codex_has_clickup(codex_config):
            result = subprocess.run(
                [args.codex_bin, "mcp", "remove", "clickup"],
                env={**os.environ, "CODEX_HOME": str(args.codex_home)},
                capture_output=True,
                check=False,
            )
            if result.returncode != 0:
                raise RuntimeError(f"Codex could not retire ClickUp (exit {result.returncode})")
        for path, (content, mode) in planned:
            replace_atomic(path, content, mode)
    except (OSError, ValueError, RuntimeError) as error:
        print(f"ClickUp MCP retirement stopped: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
