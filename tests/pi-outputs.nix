{ flake, flakePath }:

let
  pi = flake.nixosConfigurations.pi;
  piHome = flake.homeConfigurations."iperez@pi";
  piHomeOptions = piHome.config;
  piPackageNames = map (package: package.name or "") piHomeOptions.home.packages;
  source = builtins.readFile (flakePath + "/flake.nix");
  piSystem = pi.pkgs.stdenv.hostPlatform.system;
  piOptions = pi.config;
  piSource = builtins.readFile (flakePath + "/hosts/pi/default.nix");
  hardwareSource = builtins.readFile (flakePath + "/hosts/pi/hardware-configuration.nix");
  virtualisationSource = builtins.readFile (flakePath + "/hosts/pi/virtualisation.nix");
  wireguardSource = builtins.readFile (flakePath + "/hosts/pi/wireguard.nix");
in
assert flake ? pkgsPi;
assert flake.pkgsPi.stdenv.hostPlatform.system == "aarch64-linux";
assert flake ? nixosConfigurations;
assert flake ? homeConfigurations;
assert piSystem == "aarch64-linux";
assert piHome.pkgs.stdenv.hostPlatform.system == "aarch64-linux";
assert piHomeOptions.home.username == "iperez";
assert piHomeOptions.home.homeDirectory == "/home/iperez";
assert piHomeOptions.home.stateVersion == "26.05";
assert piHomeOptions.programs.zsh.enable;
assert piHomeOptions.programs.git.enable;
assert piHomeOptions.programs.tmux.enable;
assert piHomeOptions.programs.direnv.enable;
assert piHomeOptions.programs.uv.enable;
assert piHomeOptions.programs.go.enable;
assert piHomeOptions.programs.awscli.enable;
assert piHomeOptions.programs.delta.enable;
assert piHomeOptions.programs.fd.enable;
assert piHomeOptions.programs.fastfetch.enable;
assert piHomeOptions.programs.nh.enable;
assert piHomeOptions.programs.codex.enable;
assert piHomeOptions.programs.claude-code.enable;
assert piHomeOptions.programs.opencode.enable;
assert piHomeOptions.programs.pi.coding-agent.enable;
assert builtins.any (name: builtins.match "gh-.*" name != null) piPackageNames;
assert builtins.any (name: builtins.match "glab-.*" name != null) piPackageNames;
assert builtins.any (name: builtins.match "nodejs-.*" name != null) piPackageNames;
assert builtins.any (name: builtins.match "pnpm-.*" name != null) piPackageNames;
assert builtins.any (name: builtins.match "python3-.*" name != null) piPackageNames;
assert builtins.any (name: builtins.match "openssl-.*" name != null) piPackageNames;
assert builtins.any (name: builtins.match "curl-.*" name != null) piPackageNames;
assert builtins.any (name: builtins.match "wget-.*" name != null) piPackageNames;
assert builtins.all (name: builtins.all (pattern: builtins.match pattern name == null) [
  ".*claude-desktop.*"
  ".*maestro-studio.*"
  ".*warp-terminal.*"
  ".*obsidian.*"
  ".*postman.*"
  ".*cartero.*"
  ".*dbeaver.*"
]) piPackageNames;
assert piHomeOptions.services.udiskie.enable == false;
assert piHomeOptions.services.syncthing.enable == false;
assert piHomeOptions.xdg.configFile."systemd/user/build.slice".text == ''
  [Unit]
  Description=CPU-capped slice for headless builds

  [Slice]
  CPUQuota=600%
  CPUWeight=50
  IOWeight=50
  TasksMax=infinity
'';
assert piHomeOptions.xdg.configFile."systemd/user/background.slice".text == ''
  [Unit]
  Description=Low-priority slice for headless background services

  [Slice]
  CPUWeight=25
  IOWeight=25
  TasksMax=infinity
'';
assert !(piHomeOptions.xdg.configFile ? "systemd/user/app.slice.d/priority.conf");
assert piOptions.networking.hostName == "pi";
assert piOptions.system.stateVersion == "26.05";
assert piOptions.time.timeZone == "America/Montevideo";
assert piOptions.boot.kernelPackages.kernel.version == pi.pkgs.linuxPackages_latest.kernel.version;
assert builtins.elem "nvme" piOptions.boot.initrd.availableKernelModules;
assert piOptions.fileSystems."/".device == "/dev/disk/by-uuid/88e0bafc-fda9-4bb1-8a72-8847b784a016";
assert piOptions.fileSystems."/".fsType == "ext4";
assert piOptions.fileSystems."/boot".device == "/dev/disk/by-uuid/56AD-3F13";
assert piOptions.fileSystems."/boot".fsType == "vfat";
assert piOptions.boot.loader.systemd-boot.enable;
assert piOptions.boot.loader.efi.canTouchEfiVariables;
assert
  piOptions.networking.interfaces.enP4p65s0.ipv4.addresses == [
    {
      address = "10.42.0.2";
      prefixLength = 24;
    }
  ];
assert piOptions.networking.defaultGateway.address == "10.42.0.1";
assert
  piOptions.networking.nameservers == [
    "1.1.1.1"
    "8.8.8.8"
  ];
assert piOptions.services.openssh.enable;
assert piOptions.services.openssh.settings.PasswordAuthentication == false;
assert piOptions.services.openssh.settings.KbdInteractiveAuthentication == false;
assert piOptions.services.openssh.settings.PermitRootLogin == "no";
assert builtins.length piOptions.users.users.iperez.openssh.authorizedKeys.keys > 0;
assert piOptions.users.users.iperez.openssh.authorizedKeys.keys == [
  "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCWZRjt2GVSLcoBvSOS9AlxAxdQ/vvvFHLeT8m9KN3LEIEDB3ZiioX3sHt2xuIq5iKSZw+Co2iv3N0XYDmJ5ktElp2allK78xeQJ35BQmpNwPZCbiBHVDmJxeLLmRNilLz6NHWkjO+4qgyJGEgRJaUYDz8wg3RSPocDsVNIJhQ8TjmcPzAXTeb0v+tNR6CrvgQ0rux8XK6XQbpdJgv5Xi5Qi3ULTwRPR0v3fvYNJMKl6O9R7BsWUNGkN3/wlkeUfFPCMGU2+XCna6RQtLTGqyJ9o++yIxEcHVuWKNj8/32SnAuu1M0ZiJIo9TN48bN59MZ5msCFW0TmJoaNsIasZYvh"
];
assert builtins.elem "wheel" piOptions.users.users.iperez.extraGroups;
assert builtins.elem "iperez" piOptions.nix.settings.trusted-users;
assert piOptions.virtualisation.podman.enable;
assert piOptions.virtualisation.libvirtd.enable == false;
assert piOptions.services.postgresql.enable == false;
assert piOptions.services.mysql.enable == false;
assert piOptions.services.xserver.enable == false;
assert builtins.match ".*rk3588.*" piSource == null;
assert builtins.match ".*rk3588.*" hardwareSource == null;
assert builtins.match ".*rk3588.*" virtualisationSource == null;
assert builtins.match ".*rk3588.*" wireguardSource == null;
assert builtins.match ".*epsilon = nixpkgs.lib.nixosSystem.*" source != null;
assert builtins.match ".*zeta = nixpkgs.lib.nixosSystem.*" source != null;
{
  pkgsPiSystem = flake.pkgsPi.stdenv.hostPlatform.system;
  piSystem = piSystem;
  piHomeSystem = piHome.pkgs.stdenv.hostPlatform.system;
}
