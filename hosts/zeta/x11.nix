{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    freerdp
    xrandr
    arandr
    xset
    xsetroot
    xclip
    betterlockscreen
    xss-lock
  ];

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [ xdg-desktop-portal-gtk ];
    config.common.default = [ "gtk" ];
  };

  services = {
    xserver = {
      enable = true;
      dpi = 96;
      displayManager = {
        sessionCommands = ''
          set -g visual-bell off
          # xinput set-prop "TPPS/2 Elan TrackPoint" "libinput Accel Speed" -0.6
          export XCURSOR_SIZE=12
          xmodmap -e "remove Lock = Caps_Lock"
          xmodmap -e "keycode 66 = Control_L"
          xmodmap -e "add Control = Control_L"
          ${pkgs.xss-lock}/bin/xss-lock --transfer-sleep-lock -- ${pkgs.betterlockscreen}/bin/betterlockscreen -l &
        '';
      };
      xkb = {
        layout = "us";
        variant = "";
      };
      autoRepeatDelay = 200;
      autoRepeatInterval = 40;
    };

    libinput.enable = true;
    displayManager.ly.enable = true;
    logind.lidSwitch = "suspend";

    geoclue2.enable = true;
    redshift = {
      enable = true;
      temperature = {
        day = 4000;
        night = 4000;
      };
    };
  };
}
