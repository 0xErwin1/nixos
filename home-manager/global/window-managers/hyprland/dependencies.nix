{ pkgs, ... }:
{
  home = {
    packages = with pkgs; [
      brightnessctl
      jq
      socat
      pamixer
      playerctl
      wayland
      grim
      slurp
      swappy
      satty
      wl-clipboard
      hyprpaper
      hyprlock
      hyprshot
      # FileChooser/OpenURI portal backend. Home Manager pins
      # NIX_XDG_DESKTOP_PORTAL_DIR to ~/.nix-profile, so backends installed only
      # via the system-level xdg.portal.extraPortals are invisible to
      # xdg-desktop-portal under this user session. Installing it here makes
      # gtk.portal land in the user profile so FileChooser/OpenURI resolve.
      xdg-desktop-portal-gtk
    ];
  };
}
