{ pkgs, lib, ... }:
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
    ];

    activation = {
      trackpoint = lib.hm.dag.entryAfter [ "xserver" ] ''
        xinput set-prop "TPPS/2 Elan TrackPoint" "libinput Accel Speed" -0.6
      '';

      xmodmap = lib.hm.dag.entryAfter [ "xserver" ] ''
        xmodmap -e "remove Lock = Caps_Lock"
        xmodmap -e "keycode 66 = Control_L"
        xmodmap -e "add Control = Control_L"
      '';
    };
  };

  xsession.initExtra = ''
    lxsession &
    nitrogen --restore &
    nm-applet &
    blueman-adapters &
    battery &
    volumeicon &
  '';
}
