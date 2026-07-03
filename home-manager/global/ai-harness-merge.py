"""Merge an AI harness MCP fragment into a runtime-owned agent config file.

A whole-file render would clobber the agent's own runtime state (Claude Code's
OAuth account and project history in ~/.claude.json; Codex's project trust
levels, notices, and plugin state in ~/.codex/config.toml). Those files are
owned and rewritten by the agent at runtime, so Home Manager may only own the
MCP section and must leave everything else intact.

Three merge kinds are supported:

  json-mcpservers  Set the top-level "mcpServers" object of a JSON document to
                   the fragment (which is that object's value).
  json-deep-merge  Recursively merge the fragment object into a JSON document,
                   overriding only the keys it declares and leaving every other
                   key (including sibling keys inside merged objects) intact.
  toml-mcpservers  Replace every top-level [mcp_servers*] table of a TOML
                   document with the fragment's tables, preserving all other
                   tables and the file preamble.

@VAR@ placeholders in the fragment are substituted from the process
environment (the secret env files are sourced by the caller before this runs).
A placeholder whose variable is unset or empty aborts the merge so a missing
token is caught instead of silently shipped. Rendered files keep the target's
existing permission bits, or 0600 when the target is created.
"""

import json
import os
import re
import sys

PLACEHOLDER = re.compile(r"@([A-Z][A-Z0-9_]*)@")
TABLE_HEADER = re.compile(r"^\s*\[\[?(?P<name>[^\]]+)\]\]?")


def substitute_secrets(text, target):
    missing = []

    def replace(match):
        name = match.group(1)
        value = os.environ.get(name)
        if not value:
            missing.append(name)
            return match.group(0)
        return value

    rendered = PLACEHOLDER.sub(replace, text)

    if missing:
        sys.stderr.write(
            "AI harness MCP merge failed for {}; missing values for: {}\n".format(
                target, ", ".join(sorted(set(missing)))
            )
        )
        sys.exit(1)

    return rendered


def target_mode(target, default=0o600):
    try:
        return os.stat(target).st_mode & 0o777
    except FileNotFoundError:
        return default


def write_atomic(target, text, mode):
    tmp = target + ".tmp"

    fd = os.open(tmp, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, mode)
    with os.fdopen(fd, "w", encoding="utf-8") as handle:
        handle.write(text)

    os.chmod(tmp, mode)
    os.replace(tmp, target)


def merge_json_mcpservers(fragment, target):
    servers = json.loads(fragment)

    document = {}
    if os.path.exists(target):
        with open(target, encoding="utf-8") as handle:
            document = json.load(handle)

    document["mcpServers"] = servers

    rendered = json.dumps(document, indent=2, ensure_ascii=False) + "\n"
    write_atomic(target, rendered, target_mode(target))


def deep_merge(base, overlay):
    for key, value in overlay.items():
        if isinstance(value, dict) and isinstance(base.get(key), dict):
            deep_merge(base[key], value)
        else:
            base[key] = value
    return base


def merge_json_deep(fragment, target):
    overlay = json.loads(fragment)

    document = {}
    if os.path.exists(target):
        with open(target, encoding="utf-8") as handle:
            document = json.load(handle)

    deep_merge(document, overlay)

    rendered = json.dumps(document, indent=2, ensure_ascii=False) + "\n"
    write_atomic(target, rendered, target_mode(target))


def strip_mcp_server_tables(text):
    result = []
    skipping = False

    for line in text.splitlines(keepends=True):
        match = TABLE_HEADER.match(line)
        if match:
            name = match.group("name").strip()
            skipping = name == "mcp_servers" or name.startswith("mcp_servers.")

        if not skipping:
            result.append(line)

    return "".join(result)


def merge_toml_mcpservers(fragment, target):
    existing = ""
    if os.path.exists(target):
        with open(target, encoding="utf-8") as handle:
            existing = handle.read()

    kept = strip_mcp_server_tables(existing).rstrip("\n")
    body = fragment.strip("\n")

    rendered = (kept + "\n\n" + body + "\n") if kept else (body + "\n")
    write_atomic(target, rendered, target_mode(target))


KINDS = {
    "json-mcpservers": merge_json_mcpservers,
    "json-deep-merge": merge_json_deep,
    "toml-mcpservers": merge_toml_mcpservers,
}


def main():
    kind, template, target = sys.argv[1], sys.argv[2], sys.argv[3]

    if kind not in KINDS:
        sys.stderr.write("AI harness MCP merge: unknown kind {}\n".format(kind))
        sys.exit(1)

    with open(template, encoding="utf-8") as handle:
        fragment = substitute_secrets(handle.read(), target)

    KINDS[kind](fragment, target)


if __name__ == "__main__":
    main()
