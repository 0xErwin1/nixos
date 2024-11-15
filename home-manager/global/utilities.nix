{ pkgs, ... }:
{
  home.packages = with pkgs; [
    nchat
    ncdu
    tokei
    fastfetch
    onefetch
    eza
    bat
    zsh
    curl
    wget
    btop
    delta
    kalker
    udiskie
    fd
    ripgrep
    pcmanfm
    ranger
    yazi
    (rustPlatform.buildRustPackage rec {
      pname = "tomlq";
      version = "0.1.6";
      src = fetchFromGitHub {
        owner = "cryptaliagy";
        repo = "tomlq";
        rev = "${version}";
        sha256 = "sha256-g8xjz8qCTiulTwcEbLTHYldw4PI+4ZfCOMJs+J6L1C4=";
      };
      cargoHash = "sha256-/cepTVJoBM1LYZkFpH9UCvE74cSszHDaeThsZksQ1P8=";
    })
  ];

  programs = {
    taskwarrior = {
      package = pkgs.taskwarrior3;
      enable = true;
      config = {
        weekly = {
          due = true;
          reminder = true;
          report = true;
        };
        monthly = {
          due = true;
          reminder = true;
          report = true;
        };
        data = {
          location = "~/.task";
        };
      };
    };
  };
}
