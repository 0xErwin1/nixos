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
  toml-mcpservers  Replace every top-level [mcp_servers] / [mcp_servers.*]
                   table of a TOML document with the fragment's tables,
                   preserving all other tables and the file preamble.
  toml-mcp-permissions
                   Replace a marked block containing canonical [mcp.*] and
                   [permissions] tables in an Agens TOML document. On first
                   use, remove same-name canonical tables and canonical MCP
                   descendants before adding the managed block; preserve every
                   other setting.

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
AGENS_MANAGED_NAME = "agens-mcp-permissions"
AGENS_MANAGED_BEGIN = f"# BEGIN HOME MANAGER MANAGED: {AGENS_MANAGED_NAME}"
AGENS_MANAGED_END = f"# END HOME MANAGER MANAGED: {AGENS_MANAGED_NAME}"


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
    with os.fdopen(fd, "w", encoding="utf-8", newline="") as handle:
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


def strip_tables(text, prefixes):
    """Drop `[prefix]` and `[prefix.*]` tables, keeping every other line.

    The dot is required for the sub-table match so a sibling table that merely
    shares the prefix as a word stem is preserved -- `[mcp_defaults]` must
    survive a merge scoped to `mcp`.
    """
    result = []
    skipping = False

    for line in text.splitlines(keepends=True):
        match = TABLE_HEADER.match(line)
        if match:
            name = match.group("name").strip()
            skipping = any(
                name == prefix or name.startswith(prefix + ".") for prefix in prefixes
            )

        if not skipping:
            result.append(line)

    return "".join(result)


def merge_toml_tables(fragment, target, prefixes):
    existing = ""
    if os.path.exists(target):
        with open(target, encoding="utf-8") as handle:
            existing = handle.read()

    kept = strip_tables(existing, prefixes).rstrip("\n")
    body = fragment.strip("\n")

    rendered = (kept + "\n\n" + body + "\n") if kept else (body + "\n")
    write_atomic(target, rendered, target_mode(target))


def toml_table_name(line):
    """Return a TOML table name as key segments, or None for a non-header.

    Quoted keys are decoded so `[mcp."local server"]` and a canonical table
    with the same quoted name compare equal. Array-table headers are accepted
    so legacy descendants can be removed with their canonical server.
    """
    name = toml_header_key(line)
    if name is None:
        return None

    segments = []
    index = 0
    while index < len(name):
        while index < len(name) and name[index].isspace():
            index += 1
        if index >= len(name):
            return None

        if name[index] in ('"', "'"):
            quote = name[index]
            start = index
            index += 1
            while index < len(name):
                if quote == '"' and name[index] == "\\":
                    index += 2
                    continue
                if name[index] == quote:
                    index += 1
                    break
                index += 1
            else:
                return None
            key = name[start:index]
            if quote == '"':
                try:
                    key = json.loads(key)
                except json.JSONDecodeError:
                    return None
            else:
                key = key[1:-1]
        else:
            start = index
            while index < len(name) and name[index] not in ". \t":
                index += 1
            key = name[start:index]
            if not key:
                return None

        segments.append(key)
        while index < len(name) and name[index].isspace():
            index += 1
        if index == len(name):
            return tuple(segments)
        if name[index] != ".":
            return None
        index += 1

    return None


def toml_string_state_after_line(line, state):
    """Track TOML multiline strings without interpreting their contents."""
    index = 0
    while index < len(line):
        if state == '"""':
            if line.startswith('"""', index):
                state = None
                index += 3
            elif line[index] == "\\":
                index += 2
            else:
                index += 1
            continue

        if state == "'''":
            if line.startswith("'''", index):
                state = None
                index += 3
            else:
                index += 1
            continue

        if line[index] == "#":
            break
        if line.startswith('"""', index):
            state = '"""'
            index += 3
            continue
        if line.startswith("'''", index):
            state = "'''"
            index += 3
            continue
        if line[index] not in ('"', "'"):
            index += 1
            continue

        quote = line[index]
        index += 1
        while index < len(line):
            if quote == '"' and line[index] == "\\":
                index += 2
            elif line[index] == quote:
                index += 1
                break
            else:
                index += 1

    return state


def toml_lines(text):
    """Return source lines with offsets and multiline-string visibility."""
    result = []
    state = None
    offset = 0

    for line in text.splitlines(keepends=True):
        content = line.rstrip("\r\n")
        result.append((offset, offset + len(line), content, state is None))
        state = toml_string_state_after_line(line, state)
        offset += len(line)

    return result


def toml_header_key(line):
    """Extract a table key while respecting quoted keys and trailing comments."""
    source = line.rstrip("\r\n").lstrip()
    if source.startswith("[["):
        opening_length = 2
        closing = "]]"
    elif source.startswith("["):
        opening_length = 1
        closing = "]"
    else:
        return None

    quote = None
    index = opening_length
    while index < len(source):
        if quote is not None:
            if quote == '"' and source[index] == "\\":
                index += 2
            elif source[index] == quote:
                quote = None
                index += 1
            else:
                index += 1
            continue

        if source[index] in ('"', "'"):
            quote = source[index]
            index += 1
            continue
        if source.startswith(closing, index):
            remainder = source[index + len(closing) :].strip()
            if remainder and not remainder.startswith("#"):
                return None
            return source[opening_length:index].strip()
        index += 1

    return None


def toml_table_blocks(text):
    """Return `(name, text)` pairs for table blocks in source order."""
    lines = text.splitlines(keepends=True)
    headers = [
        (index, toml_table_name(line))
        for index, (_, _, line, structural) in enumerate(toml_lines(text))
        if structural and toml_table_name(line) is not None
    ]
    return [
        (name, "".join(lines[start:end]))
        for (start, name), (end, _) in zip(headers, headers[1:] + [(len(lines), None)])
    ]


def canonical_agens_blocks(fragment):
    """Return canonical Agens table roots and their source blocks."""
    blocks = [
        (name, block)
        for name, block in toml_table_blocks(fragment)
        if name == ("permissions",) or (name and name[0] == "mcp" and len(name) > 1)
    ]
    roots = {
        name if name == ("permissions",) else name[:2]
        for name, _ in blocks
    }
    return roots, blocks


def is_legacy_managed_table(name, roots):
    return any(
        name == root or (root[0] == "mcp" and name[: len(root)] == root)
        for root in roots
    )


def strip_legacy_managed_tables(text, roots):
    """Remove canonical legacy tables while retaining exterior TOML trivia."""
    result = []
    skipping = False

    for start, end, content, structural in toml_lines(text):
        line = text[start:end]
        name = toml_table_name(content) if structural else None
        if name is not None:
            skipping = is_legacy_managed_table(name, roots)

        trivia = structural and (
            not content.strip() or content.lstrip().startswith("#")
        )
        if not skipping or trivia:
            result.append(line)

    return "".join(result)


def managed_block_bounds(text, target):
    """Return managed block bounds, or None when the target is unmarked."""
    begin_lines = []
    end_lines = []
    for start, end, content, structural in toml_lines(text):
        if not structural:
            continue
        if content == AGENS_MANAGED_BEGIN:
            begin_lines.append((start, end))
        elif content == AGENS_MANAGED_END:
            end_lines.append((start, end))

    if not begin_lines and not end_lines:
        return None
    if len(begin_lines) != 1 or len(end_lines) != 1:
        raise ValueError(
            f"AI harness MCP merge failed for {target}; corrupt Agens managed markers"
        )

    begin_start, _ = begin_lines[0]
    end_start, end = end_lines[0]
    if end_start <= begin_start:
        raise ValueError(
            f"AI harness MCP merge failed for {target}; corrupt Agens managed markers"
        )

    return begin_start, end


def render_agens_managed_block(blocks):
    body = "".join(block for _, block in blocks).strip("\n")
    return f"{AGENS_MANAGED_BEGIN}\n{body}\n{AGENS_MANAGED_END}\n"


def merge_toml_mcp_permissions(fragment, target):
    """Replace Home Manager's marked Agens tables without owning the file."""
    existing = ""
    if os.path.exists(target):
        with open(target, encoding="utf-8", newline="") as handle:
            existing = handle.read()

    canonical_names, canonical_blocks = canonical_agens_blocks(fragment)
    managed = render_agens_managed_block(canonical_blocks)
    bounds = managed_block_bounds(existing, target)

    if bounds is not None:
        start, end = bounds
        rendered = existing[:start] + managed + existing[end:]
    else:
        kept = strip_legacy_managed_tables(existing, canonical_names)
        separator = "" if not kept or kept.endswith("\n") else "\n"
        spacer = "\n" if kept else ""
        rendered = kept + separator + spacer + managed

    write_atomic(target, rendered, target_mode(target))


KINDS = {
    "json-mcpservers": merge_json_mcpservers,
    "json-deep-merge": merge_json_deep,
    "toml-mcpservers": lambda fragment, target: merge_toml_tables(
        fragment, target, ("mcp_servers",)
    ),
    "toml-mcp-permissions": merge_toml_mcp_permissions,
}


def main():
    kind, template, target = sys.argv[1], sys.argv[2], sys.argv[3]

    if kind not in KINDS:
        sys.stderr.write("AI harness MCP merge: unknown kind {}\n".format(kind))
        sys.exit(1)

    with open(template, encoding="utf-8") as handle:
        fragment = substitute_secrets(handle.read(), target)

    try:
        KINDS[kind](fragment, target)
    except ValueError as error:
        sys.stderr.write(f"{error}\n")
        sys.exit(1)


if __name__ == "__main__":
    main()
