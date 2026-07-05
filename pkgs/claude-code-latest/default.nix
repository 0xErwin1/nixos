{ pkgs }:

let
  inherit (pkgs)
    lib
    stdenv
    fetchurl
    glibc
    ;

  pname = "claude-code-latest";
  version = "2.1.199";

  sources = {
    x86_64-linux = {
      platform = "linux-x64";
      loader = "ld-linux-x86-64.so.2";
      hash = "sha256-9U5py8ibLaYaQVcAr3/1KhR+hiUX1PGw7s92hEjPf4M=";
    };

    aarch64-linux = {
      platform = "linux-arm64";
      loader = "ld-linux-aarch64.so.1";
      hash = "sha256-G7nQMkQKdVMvfdTK+8aH8iCq8Wxj66F+GS377C8EvSU=";
    };
  };

  source =
    sources.${stdenv.hostPlatform.system}
      or (throw "Unsupported system for ${pname}: ${stdenv.hostPlatform.system}");

  # The release artifact is a Bun single-file executable: the JS bundle is
  # appended to the runtime and located by a byte offset stored in the binary.
  # patchelf/autoPatchelf rewrite the ELF and shift that offset, which makes Bun
  # silently fall back to its plain runtime CLI. The binary must stay untouched,
  # so the dynamic loader is supplied through a wrapper instead of patchelf.
  libPath = lib.makeLibraryPath [
    glibc
    stdenv.cc.cc.lib
  ];
in
stdenv.mkDerivation {
  inherit pname version;

  src = fetchurl {
    url = "https://downloads.claude.ai/claude-code-releases/${version}/${source.platform}/claude";
    inherit (source) hash;
  };

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;
  dontPatchELF = true;
  dontStrip = true;

  installPhase = ''
    runHook preInstall

    install -Dm755 "$src" "$out/libexec/claude-code/claude"

    # This binary is launched through the dynamic loader, so Claude Code sees the
    # loader (not itself) as its exec path and its bundled-ripgrep/grep shell
    # interception mis-fires (`ld.so -G ...`). Fall back to the system ripgrep,
    # which is the documented remedy when the bundled ripgrep does not run.
    # Keep argv[0] as "claude" so terminal integrations such as tmux automatic
    # window renaming do not display the dynamic loader as the active command.
    mkdir -p "$out/bin"
    cat > "$out/bin/claude" <<EOF
#!${pkgs.runtimeShell}
export DISABLE_AUTOUPDATER="\''${DISABLE_AUTOUPDATER:-1}"
export USE_BUILTIN_RIPGREP="\''${USE_BUILTIN_RIPGREP:-0}"
exec -a claude "${glibc}/lib/${source.loader}" --library-path "${libPath}" "$out/libexec/claude-code/claude" "\$@"
EOF
    chmod 0755 "$out/bin/claude"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Anthropic Claude Code CLI (native Bun build, tracks the latest release)";
    homepage = "https://code.claude.com";
    license = licenses.unfree;
    mainProgram = "claude";
    platforms = builtins.attrNames sources;
    sourceProvenance = [ sourceTypes.binaryNativeCode ];
  };
}
