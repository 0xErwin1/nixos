{ ... }:
{
  xdg.configFile."niri/eww" = {
    source = ./.;
    recursive = true;
  };

  programs.eww = {
    enable = true;
  };
}
