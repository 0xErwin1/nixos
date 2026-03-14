{ pkgs, ... }:
{
  home = {
    packages = with pkgs; [
      freerdp
      cloudflared
    ];

    file = {
      ".local/bin/rdp-connect" = {
        source = ../../dotfiles/.local/bin/rdp-connect;
        executable = true;
      };

      ".local/bin/rdp-rofi" = {
        source = ../../dotfiles/.local/bin/rdp-rofi;
        executable = true;
      };

      ".local/bin/rdp-cf-connect" = {
        source = ../../dotfiles/.local/bin/rdp-cf-connect;
        executable = true;
      };
    };
  };

  xdg.configFile."rdp/hosts.example".text = ''
    # name|host|user|extra freerdp args
    # office|10.0.0.20|iperez|/sound /microphone
    # use ~/.local/bin/rdp-cf-connect for Cloudflare Access hosts
  '';
}
