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
      nerdfonts
      powerline-symbols
      noto-fonts-emoji
      noto-fonts
      noto-fonts-cjk
      liberation_ttf
      fira-code
      fira-code-symbols
      mplus-outline-fonts.githubRelease
      proggyfonts
    ];
}
