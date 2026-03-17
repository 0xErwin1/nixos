{ pkgs, ... }:
{
  home = {
    packages = with pkgs; [
      lxsession
      networkmanagerapplet
      blueman
      volumeicon
      redshift
      solaar
      xinput
      xmodmap
      xsetroot
      feh
    ];
  };

  xsession = {
    profileExtra = ''
      xinput set-prop "TPPS/2 Elan TrackPoint" "libinput Accel Speed" -0.6
      xmodmap -e "remove Lock = Caps_Lock"
      xmodmap -e "keycode 66 = Control_L"
      xmodmap -e "add Control = Control_L"
      export XCURSOR_THEME=Bibata-Modern-Classic
      export XCURSOR_SIZE=16
      xsetroot -cursor_name left_ptr
      xrdb -merge <<< "Xft.dpi: 96"

      lxsession &
      nm-applet &
      blueman-adapters &
      battery &
      volumeicon &

      ${pkgs.feh}/bin/feh --bg-fill ~/Wallpaper/man\ near\ Torii\ gate\ wallpaper,\ gray\ temple\ wallpaper,\ landscape.jpg
    '';
  };
}
