{ config, ... }:
{
  sops = {
    defaultSopsFile = ../../secrets/pi.yaml;
    useSystemdActivation = true;
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

    secrets = {
      "pi/wireguard-private-key" = {
        owner = "root";
        group = "root";
        mode = "0400";
        restartUnits = [ "wg-quick-wg0.service" ];
      };
      "pi/wifi-ssid" = {
        owner = "root";
        group = "root";
        mode = "0400";
      };
      "pi/wifi-psk" = {
        owner = "root";
        group = "root";
        mode = "0400";
      };
    };

    templates."networkmanager.env" = {
      owner = "root";
      group = "root";
      mode = "0400";
      content = ''
        PI_WIFI_SSID=${config.sops.placeholder."pi/wifi-ssid"}
        PI_WIFI_PSK=${config.sops.placeholder."pi/wifi-psk"}
      '';
      restartUnits = [ "NetworkManager-ensure-profiles.service" ];
    };
  };

  systemd.services.NetworkManager-ensure-profiles = {
    after = [ "sops-install-secrets.service" ];
    requires = [ "sops-install-secrets.service" ];
  };
}
