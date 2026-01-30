{ pkgs, ... }:
{
  home = {
    packages = with pkgs; [
      lxsession
      nitrogen
      networkmanagerapplet
      blueman
      picom
      volumeicon
      redshift
      solaar
      xorg.xinput
      xorg.xmodmap
    ];
  };

  xsession = {
    profileExtra = ''
      xinput set-prop "TPPS/2 Elan TrackPoint" "libinput Accel Speed" -0.6
      xmodmap -e "remove Lock = Caps_Lock"
      xmodmap -e "keycode 66 = Control_L"
      xmodmap -e "add Control = Control_L"

      nitrogen --restore
      lxsession &
      nm-applet &
      blueman-adapters &
      battery &
      volumeicon &
    '';
  };
}
