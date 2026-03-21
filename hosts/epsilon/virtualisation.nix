{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    fuse
    fuse3
    appimage-run
    cage
    wl-clipboard
    podman-tui
    dive
    docker-compose
    waydroid-nftables
  ];
  networking.nftables.enable = true;

  programs = {
    nix-ld = {
      enable = true;
      libraries = with pkgs; [
        fuse
        libusb1
        libva
      ];
    };

    virt-manager = {
      enable = true;
    };
  };

  virtualisation = {
    podman = {
      enable = true;
      dockerCompat = true;
      defaultNetwork.settings.dns_enabled = true;
    };
    libvirtd.enable = true;
    waydroid = {
      enable = true;
      package = pkgs.waydroid-nftables;
    };
  };

  users.users.iperez.extraGroups = [ "libvirtd" ];
}
