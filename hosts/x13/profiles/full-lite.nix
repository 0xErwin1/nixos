{ pkgs, ... }:
{
  location.provider = "geoclue2";

  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  services = {
    geoclue2.enable = true;
    redshift = {
      enable = true;
      temperature = {
        day = 5000;
        night = 4000;
      };
    };
    gnome.gnome-keyring.enable = true;
    blueman.enable = true;
  };

  environment.systemPackages = with pkgs; [
    wget
    qimgv
    ripgrep
    piper
    pwvucontrol
    unzip
    gzip
    zip
    wl-clipboard
    xinput
    xmodmap
  ];
}
