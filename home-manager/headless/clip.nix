{ pkgs, ... }:
# Headless hosts have no wl-copy/xclip, so shell copies must travel as OSC 52
# through the attached client (herdr passes OSC 52 through to the local
# terminal). Writing to /dev/tty keeps the sequence out of pipelines and
# redirections.
{
  home.packages = [
    (pkgs.writeShellScriptBin "clip" ''
      data=$(${pkgs.coreutils}/bin/base64 -w0)
      printf '\033]52;c;%s\a' "$data" > /dev/tty 2>/dev/null \
        || printf '\033]52;c;%s\a' "$data"
    '')
  ];
}
