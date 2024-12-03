{ pkgs, ... }:
{
  fonts = {
    fontconfig = {
      enable = true;
      defaultFonts = {
        serif = [ "LiterationSerif Nerd Font Regular" ];
        sansSerif = [ "LiterationSans Nerd Font Regular" ];
        monospace = [ "FiraCode Nerd Font" ];
      };
    };
  };

  home.packages = with pkgs; [
    nerd-fonts.liberation
    nerd-fonts.ubuntu-mono
    nerd-fonts.fira-code
    powerline-symbols
    noto-fonts-emoji
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
    liberation_ttf
    fira-code
    fira-code-symbols
    mplus-outline-fonts.githubRelease
    proggyfonts
  ];
}
