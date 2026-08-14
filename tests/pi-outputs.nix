{ flake, flakePath }:

let
  pi = flake.nixosConfigurations.pi;
  piHome = flake.homeConfigurations."iperez@pi";
  piHomeOptions = piHome.config;
  piPackageNames = map (package: package.name or "") piHomeOptions.home.packages;
  piHerdrServer = piHomeOptions.systemd.user.services.herdr-server;
  piChromiumCdp = piHomeOptions.systemd.user.services.chromium-cdp;
  piHerdrExecStart = builtins.concatStringsSep " " piHerdrServer.Service.ExecStart;
  piChromiumExecStart = builtins.concatStringsSep " " piChromiumCdp.Service.ExecStart;
  source = builtins.readFile (flakePath + "/flake.nix");
  piSystem = pi.pkgs.stdenv.hostPlatform.system;
  piOptions = pi.config;
  piDeploy = flake.deploy.nodes.pi-host;
  piSecrets = piOptions.sops.secrets;
  piNetworkManagerTemplate = piOptions.sops.templates."networkmanager.env";
  piNetworkProfiles = piOptions.networking.networkmanager.ensureProfiles.profiles;
  piWifiProfile = piNetworkProfiles.pi-wifi;
  piEthernetProfile = piNetworkProfiles.pi-ethernet;
  wireguardSecret = piSecrets."pi/wireguard-private-key";
  piSource = builtins.readFile (flakePath + "/hosts/pi/default.nix");
  hardwareSource = builtins.readFile (flakePath + "/hosts/pi/hardware-configuration.nix");
  virtualisationSource = builtins.readFile (flakePath + "/hosts/pi/virtualisation.nix");
  wireguardSource = builtins.readFile (flakePath + "/hosts/pi/wireguard.nix");
in
assert flake ? pkgsPi;
assert flake.pkgsPi.stdenv.hostPlatform.system == "aarch64-linux";
assert flake ? nixosConfigurations;
assert flake ? homeConfigurations;
assert builtins.hasAttr "sops-nix" flake.inputs;
assert !(flake.nixosConfigurations.epsilon.options ? sops);
assert !(flake.nixosConfigurations.zeta.options ? sops);
assert builtins.attrNames flake.deploy.nodes == [ "pi-host" ];
assert piDeploy.hostname == "192.168.1.100";
assert piDeploy.sshUser == "iperez";
assert
  piDeploy.profilesOrder == [
    "system"
    "home"
  ];
assert piDeploy.profiles.system.user == "root";
assert piDeploy.profiles.home.user == "iperez";
assert piDeploy.profiles.home.profilePath == "/home/iperez/.local/state/nix/profiles/home-manager";
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
assert builtins.any (name: builtins.match "kalker-.*" name != null) piPackageNames;
assert builtins.any (name: builtins.match "codegraph-.*" name != null) piPackageNames;
assert builtins.any (name: builtins.match "chromium-.*" name != null) piPackageNames;
assert builtins.all (
  name:
  builtins.all (pattern: builtins.match pattern name == null) [
    ".*claude-desktop.*"
    ".*maestro-studio.*"
    ".*warp-terminal.*"
    ".*obsidian.*"
    ".*postman.*"
    ".*cartero.*"
    ".*dbeaver.*"
  ]
) piPackageNames;
assert piHomeOptions.services.udiskie.enable == false;
assert piHomeOptions.services.syncthing.enable == false;
assert
  piHomeOptions.xdg.configFile."systemd/user/build.slice".text == ''
    [Unit]
    Description=CPU-capped slice for headless builds

    [Slice]
    CPUQuota=600%
    CPUWeight=50
    IOWeight=50
    TasksMax=infinity
  '';
assert
  piHomeOptions.xdg.configFile."systemd/user/background.slice".text == ''
    [Unit]
    Description=Low-priority slice for headless background services

    [Slice]
    CPUWeight=25
    IOWeight=25
    TasksMax=infinity
  '';
assert !(piHomeOptions.xdg.configFile ? "systemd/user/app.slice.d/priority.conf");
assert piHerdrServer.Install.WantedBy == [ "default.target" ];
assert builtins.match ".*/bin/herdr server" piHerdrExecStart != null;
assert !(piHerdrServer.Service ? Slice);
assert piChromiumCdp.Install.WantedBy == [ "default.target" ];
assert piChromiumCdp.Service.Slice == "background.slice";
assert
  builtins.match ".*--remote-debugging-address=127\\.0\\.0\\.1 --remote-debugging-port=9222.*" piChromiumExecStart
  != null;
assert builtins.match ".*(0\\.0\\.0\\.0|--no-sandbox).*" piChromiumExecStart == null;
assert piOptions.networking.hostName == "pi";
assert piOptions.system.stateVersion == "26.05";
assert piOptions.time.timeZone == "America/Montevideo";
assert piOptions.boot.kernelPackages.kernel.version == pi.pkgs.linuxPackages_latest.kernel.version;
assert builtins.elem "nvme" piOptions.boot.initrd.availableKernelModules;
assert piOptions.hardware.enableRedistributableFirmware;
assert piOptions.fileSystems."/".device == "/dev/disk/by-uuid/88e0bafc-fda9-4bb1-8a72-8847b784a016";
assert piOptions.fileSystems."/".fsType == "ext4";
assert piOptions.fileSystems."/boot".device == "/dev/disk/by-uuid/56AD-3F13";
assert piOptions.fileSystems."/boot".fsType == "vfat";
assert piOptions.boot.loader.systemd-boot.enable;
assert piOptions.boot.loader.efi.canTouchEfiVariables;
assert piOptions.networking.networkmanager.enable;
assert piOptions.networking.networkmanager.unmanaged == [ ];
assert piOptions.networking.networkmanager.wifi.powersave == false;
assert
  builtins.attrNames piNetworkProfiles == [
    "pi-ethernet"
    "pi-wifi"
  ];
assert piWifiProfile.connection.id == "pi-wifi";
assert piWifiProfile.connection.type == "wifi";
assert piWifiProfile.connection.interface-name == "wlu1";
assert piWifiProfile.connection.uuid == "4695ce6d-f84f-4354-bd4f-75c7dc65adae";
assert piWifiProfile.wifi.mode == "infrastructure";
assert piWifiProfile.wifi.ssid == "$PI_WIFI_SSID";
assert piWifiProfile.wifi-security.key-mgmt == "wpa-psk";
assert piWifiProfile.wifi-security.psk == "$PI_WIFI_PSK";
assert piWifiProfile.ipv4.address1 == "192.168.1.100/24,192.168.1.1";
assert piWifiProfile.ipv4.dns == "192.168.1.1;";
assert piWifiProfile.ipv4.method == "manual";
assert piEthernetProfile.connection.id == "pi-ethernet";
assert piEthernetProfile.connection.type == "ethernet";
assert piEthernetProfile.connection.interface-name == "enP4p65s0";
assert piEthernetProfile.ipv4.method == "auto";
assert piOptions.networking.defaultGateway == null;
assert piOptions.networking.nameservers == [ ];
assert !(piOptions.networking.interfaces ? enP4p65s0);
assert
  piOptions.networking.networkmanager.ensureProfiles.environmentFiles
  == [ piNetworkManagerTemplate.path ];
assert piNetworkManagerTemplate.path == "/run/secrets/rendered/networkmanager.env";
assert piNetworkManagerTemplate.owner == "root";
assert piNetworkManagerTemplate.group == "root";
assert piNetworkManagerTemplate.mode == "0400";
assert
  piNetworkManagerTemplate.content == ''
    PI_WIFI_SSID=${piOptions.sops.placeholder."pi/wifi-ssid"}
    PI_WIFI_PSK=${piOptions.sops.placeholder."pi/wifi-psk"}
  '';
assert piNetworkManagerTemplate.restartUnits == [ "NetworkManager-ensure-profiles.service" ];
assert builtins.elem "sops-install-secrets.service"
  piOptions.systemd.services.NetworkManager-ensure-profiles.after;
assert builtins.elem "sops-install-secrets.service"
  piOptions.systemd.services.NetworkManager-ensure-profiles.requires;
assert builtins.baseNameOf piOptions.sops.defaultSopsFile == "pi.yaml";
assert piOptions.sops.useSystemdActivation;
assert piOptions.sops.age.sshKeyPaths == [ "/etc/ssh/ssh_host_ed25519_key" ];
assert
  builtins.attrNames piSecrets == [
    "pi/wifi-psk"
    "pi/wifi-ssid"
    "pi/wireguard-private-key"
  ];
assert builtins.all (
  secret: secret.owner == "root" && secret.group == "root" && secret.mode == "0400"
) (builtins.attrValues piSecrets);
assert piOptions.services.openssh.enable;
assert piOptions.services.openssh.settings.PasswordAuthentication == false;
assert piOptions.services.openssh.settings.KbdInteractiveAuthentication == false;
assert piOptions.services.openssh.settings.PermitRootLogin == "no";
assert piOptions.services.openssh.settings.X11Forwarding;
assert piOptions.programs.ssh.setXAuthLocation;
assert piOptions.users.users.iperez.linger == true;
assert builtins.length piOptions.users.users.iperez.openssh.authorizedKeys.keys > 0;
assert
  piOptions.users.users.iperez.openssh.authorizedKeys.keys == [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCWZRjt2GVSLcoBvSOS9AlxAxdQ/vvvFHLeT8m9KN3LEIEDB3ZiioX3sHt2xuIq5iKSZw+Co2iv3N0XYDmJ5ktElp2allK78xeQJ35BQmpNwPZCbiBHVDmJxeLLmRNilLz6NHWkjO+4qgyJGEgRJaUYDz8wg3RSPocDsVNIJhQ8TjmcPzAXTeb0v+tNR6CrvgQ0rux8XK6XQbpdJgv5Xi5Qi3ULTwRPR0v3fvYNJMKl6O9R7BsWUNGkN3/wlkeUfFPCMGU2+XCna6RQtLTGqyJ9o++yIxEcHVuWKNj8/32SnAuu1M0ZiJIo9TN48bN59MZ5msCFW0TmJoaNsIasZYvh"
  ];
assert builtins.elem "wheel" piOptions.users.users.iperez.extraGroups;
assert builtins.elem "networkmanager" piOptions.users.users.iperez.extraGroups;
assert piOptions.users.users.iperez.shell == pi.pkgs.zsh;
assert builtins.elem "iperez" piOptions.nix.settings.trusted-users;
assert piOptions.programs.zsh.enable;
assert piOptions.virtualisation.podman.enable;
assert piOptions.virtualisation.libvirtd.enable == false;
assert builtins.elem "wg0" piOptions.networking.firewall.trustedInterfaces;
assert
  piOptions.networking.wg-quick.interfaces.wg0.dns == [
    "10.0.0.1"
    "1.1.1.1"
  ];
assert piOptions.networking.wg-quick.interfaces.wg0.privateKeyFile == wireguardSecret.path;
assert wireguardSecret.path == "/run/secrets/pi/wireguard-private-key";
assert wireguardSecret.restartUnits == [ "wg-quick-wg0.service" ];
assert builtins.elem "sops-install-secrets.service" piOptions.systemd.services.wg-quick-wg0.after;
assert builtins.elem "sops-install-secrets.service"
  piOptions.systemd.services.wg-quick-wg0.requires;
assert !(piOptions.systemd.services.wg-quick-wg0.unitConfig ? ConditionPathExists);
assert piOptions.services.postgresql.enable == false;
assert piOptions.services.mysql.enable == false;
assert piOptions.services.xserver.enable == false;
# The Pi must stay on mainline nixpkgs; only the mainline DTB name may mention
# the SoC, never the vendor kernel or the nixos-rk3588 flake.
assert builtins.match ".*nixos-rk3588.*" piSource == null;
assert builtins.match ".*linux-rockchip.*" piSource == null;
assert builtins.match ".*rk3588.*" hardwareSource == null;
assert builtins.match ".*rk3588.*" virtualisationSource == null;
assert builtins.match ".*rk3588.*" wireguardSource == null;
assert piOptions.hardware.deviceTree.name == "rockchip/rk3588-orangepi-5-plus.dtb";
assert (builtins.head piOptions.hardware.deviceTree.overlays).name == "usb3-host-power";
assert piOptions.boot.loader.systemd-boot.installDeviceTree;
assert builtins.match ".*epsilon = nixpkgs.lib.nixosSystem.*" source != null;
assert builtins.match ".*zeta = nixpkgs.lib.nixosSystem.*" source != null;
{
  pkgsPiSystem = flake.pkgsPi.stdenv.hostPlatform.system;
  piSystem = piSystem;
  piHomeSystem = piHome.pkgs.stdenv.hostPlatform.system;
}
