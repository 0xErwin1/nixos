{ pkgs, lib, ... }:
{
  programs = {
    codex.enable = true;
    claude-code = {
      enable = true;
      package = pkgs.claude-code-latest;
    };
    opencode = {
      enable = true;
      package = pkgs.opencode;
    };
    uv.enable = true;
    go.enable = true;
    awscli = {
      enable = true;
      package = pkgs.awscli2;
    };
    delta.enable = true;
    fd.enable = true;
    fastfetch.enable = true;
    nh = {
      enable = true;
      flake = "/home/iperez/.config/home-manager";
      clean = {
        enable = true;
        extraArgs = "--keep-since 7d --keep 5";
      };
    };
  };

  services.udiskie = {
    enable = true;
  };

  home.packages = with pkgs; [
    ccstatusline
    (pkgs.symlinkJoin {
      name = "warp-terminal";
      paths = [ pkgs.warp-terminal ];
      nativeBuildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/warp-terminal \
          --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ pkgs.wayland ]}
      '';
    })
    calibre
    gnupg
    ncdu
    tokei
    onefetch
    curl
    wget
    kalker
    pcmanfm
    btop
    postman
    cartero

    obsidian

    glab

    engram

    pnpm
    nodejs

    openvpn
    openfortivpn
    openssl
    claude-desktop

    pi-coding-agent

    tuicr

    python3
  ];
}
