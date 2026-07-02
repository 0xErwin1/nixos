"""Render an AI harness config template by substituting @VAR@ placeholders.

Values are read from the process environment (populated by sourcing the secret
env files at activation time). The rendered file is written with mode 0600 and
never echoes secret values. Any placeholder whose variable is unset or empty
aborts the render so a missing token is caught instead of silently shipped.
"""

import os
import re
import sys

PLACEHOLDER = re.compile(r"@([A-Z][A-Z0-9_]*)@")


def main():
    template, target = sys.argv[1], sys.argv[2]
    text = open(template, encoding="utf-8").read()

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
            "AI harness secret config render failed for {}; missing values for: {}\n".format(
                target, ", ".join(sorted(set(missing)))
            )
        )
        sys.exit(1)

    tmp = target + ".tmp"
    fd = os.open(tmp, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
    with os.fdopen(fd, "w", encoding="utf-8") as handle:
        handle.write(rendered)
    os.replace(tmp, target)


if __name__ == "__main__":
    main()
