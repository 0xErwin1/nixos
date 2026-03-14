{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    fuse
    fuse3
    appimage-run
    podman-tui
    dive
    docker-compose
  ];

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
  };

  users.users.iperez.extraGroups = [ "libvirtd" ];
}
