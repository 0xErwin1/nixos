{ pkgs, ... }:
{

  imports = [ ./picom.nix ];

  home = {
    packages = with pkgs; [
      eww
      xclip
      xrandr
      arandr
      brightnessctl
      pamixer
      playerctl
      betterlockscreen
      flameshot
      networkmanagerapplet
      blueman
      udiskie
      solaar
      feh
    ];
  };

  programs = {
    rofi = {
      enable = true;
    };
  };

  # Flameshot service to run in background
  # This ensures clipboard functionality works correctly in X11
  systemd.user.services.flameshot = {
    Unit = {
      Description = "Flameshot screenshot tool";
      After = [ "graphical-session-pre.target" ];
      PartOf = [ "graphical-session.target" ];
    };

    Service = {
      ExecStart = "${pkgs.flameshot}/bin/flameshot";
      Restart = "on-failure";
      RestartSec = 3;
    };

    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };

  # Flameshot configuration for clipboard support
  xdg.configFile."flameshot/flameshot.ini".text = ''
    [General]
    disabledTrayIcon=false
    showStartupLaunchMessage=false
    copyPathAfterSave=false
    saveAfterCopy=false
    savePathFixed=false
    useJpgForClipboard=false

    [Shortcuts]
    TYPE_COPY=Ctrl+C
  '';
}
