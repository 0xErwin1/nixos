# The agent-side hooks Moshi and herdr install into the coding clients.
#
# Both tools ship an installer that writes into the same files the AI harness
# renders, so left to themselves they either lose to the next activation or win
# over it, depending on who ran last. Running their installers here instead
# turns the result into content the harness can layer, and keeps the hooks
# theirs: a version bump regenerates them rather than leaving a transcription
# from whenever this was written.
#
# The generated content records the absolute path of the home directory it was
# built for, so it is generated against a placeholder and rebased, exactly as
# the rendered harness is.

{
  pkgs,

  homeDirectory,

  # Clients to install hooks for. A name each tool does not know is an error
  # from that tool rather than something silently skipped.
  targets ? [
    "claude"
    "codex"
    "opencode"
    "pi"
  ],
}:

let
  inherit (pkgs) lib;

in
pkgs.runCommandLocal "agent-integrations"
  {
    nativeBuildInputs = [
      pkgs.moshi-hook
      pkgs.herdr
    ];

    meta.description = "Moshi and herdr agent hooks, generated for one home directory";
  }
  ''
    export HOME="$PWD/home"
    export XDG_CONFIG_HOME="$HOME/.config"
    mkdir -p "$HOME"/{.claude,.codex,.config/opencode,.pi/agent/extensions}

    # herdr refuses to install for a client whose directory does not exist,
    # which is the check that a real machine passes by having the client. Here
    # the directories are the whole point, so they are created first.
    moshi-hook install --target ${lib.escapeShellArg (lib.concatStringsSep "," targets)}
    ${lib.concatMapStringsSep "\n" (target: ''
      herdr integration install ${lib.escapeShellArg target}
    '') targets}

    mkdir -p "$out"
    cp -r "$HOME"/. "$out/"
    chmod -R u+w "$out"

    # Every generated file that names the directory it was generated against
    # has to name the one it will live in. Nothing else in this tree is a path,
    # so the substitution is whole-file rather than per-key.
    grep -rl "$HOME" "$out" | while read -r file; do
      substituteInPlace "$file" --replace "$HOME" ${lib.escapeShellArg homeDirectory}
    done

    if grep -rl "$HOME" "$out" >/dev/null 2>&1; then
      echo "generated hooks still name the build home" >&2
      exit 1
    fi
  ''
