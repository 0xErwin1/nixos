{
  config,
  pkgs,
  lib,
  ...
}:
let
  pipewire-module-xrdp = pkgs.stdenv.mkDerivation rec {
    pname = "pipewire-module-xrdp";
    version = "0.1";

    src = pkgs.fetchFromGitHub {
      owner = "neutrinolabs";
      repo = "pipewire-module-xrdp";
      rev = "v0.1";
      hash = "sha256-ZiKVAMAFBkMpZFqrn4hjZZPxdR+sBtcd4W30z8pkdzk=";
    };

    nativeBuildInputs = with pkgs; [
      autoreconfHook
      pkg-config
    ];

    buildInputs = with pkgs; [
      pipewire
    ];

    configureFlags = [
      "--prefix=${placeholder "out"}"
    ];

    installPhase = ''
      runHook preInstall

      mkdir -p $out/lib/pipewire-0.3
      mkdir -p $out/share/applications
      mkdir -p $out/bin

      cp -v src/.libs/libpipewire-module-xrdp-pipewire.so \
        $out/lib/pipewire-0.3/

      if [ -f instfiles/pipewire-xrdp.desktop ]; then
        cp -v instfiles/pipewire-xrdp.desktop $out/share/applications/
      fi

      if [ -f load_pw_modules.sh ]; then
        cp -v load_pw_modules.sh $out/bin/
        chmod +x $out/bin/load_pw_modules.sh
      fi

      runHook postInstall
    '';
  };
in
{
  environment.systemPackages = with pkgs; [
    pipewire-module-xrdp
  ];

  xdg.configFile."autostart/pipewire-xrdp.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=pipewire-xrdp
    Exec=${pipewire-module-xrdp}/bin/load_pw_modules.sh
    OnlyShowIn=XFCE;
    X-GNOME-Autostart-enabled=true
  '';

  services = {
    xserver = {
      enable = true;
      desktopManager.xfce.enable = true;
    };
    xrdp = {
      enable = true;
      openFirewall = false;
      defaultWindowManager = "xfce4-session";
      audio = {
        enable = true;
      };
    };
  };

  # cloudflared tunnel exposes xrdp to Cloudflare Access without opening the
  # port to the internet. The tunnel token is read from a file outside the Nix
  # store so it is never committed to the repo.
  #
  # Setup (once, on epsilon):
  #   sudo mkdir -p /etc/cloudflared
  #   echo "CLOUDFLARED_TOKEN=<your-token>" | sudo tee /etc/cloudflared/rdp.env
  #   sudo chmod 600 /etc/cloudflared/rdp.env
  #
  # The tunnel itself (with the TCP ingress rule pointing to localhost:3389)
  # must be created in the Cloudflare dashboard first.
  systemd.services.cloudflared-rdp = {
    description = "Cloudflare Tunnel — RDP";
    after = [
      "network-online.target"
      "xrdp.service"
    ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "simple";
      EnvironmentFile = "/etc/cloudflared/rdp.env";
      ExecStart = "${pkgs.cloudflared}/bin/cloudflared tunnel --no-autoupdate run --token $${CLOUDFLARED_TOKEN}";
      Restart = "on-failure";
      RestartSec = "5s";
    };
  };

  # Allow RDP from:
  #   - WireGuard / LAN (direct IP access)
  #   - 127.0.0.1 (cloudflared tunnel proxy)
  networking.firewall.extraCommands = ''
    iptables -A INPUT -p tcp --dport 3389 -s 127.0.0.1 -j ACCEPT
    iptables -A INPUT -p tcp --dport 3389 -s 10.0.0.0/8 -j ACCEPT
    iptables -A INPUT -p tcp --dport 3389 -s 192.168.0.0/16 -j ACCEPT
    iptables -A INPUT -p tcp --dport 3389 -j DROP
  '';

  networking.firewall.extraStopCommands = ''
    iptables -D INPUT -p tcp --dport 3389 -s 127.0.0.1 -j ACCEPT || true
    iptables -D INPUT -p tcp --dport 3389 -s 10.0.0.0/8 -j ACCEPT || true
    iptables -D INPUT -p tcp --dport 3389 -s 192.168.0.0/16 -j ACCEPT || true
    iptables -D INPUT -p tcp --dport 3389 -j DROP || true
  '';
}
