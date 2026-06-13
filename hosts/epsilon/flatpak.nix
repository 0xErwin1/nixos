{
  services.flatpak = {
    enable = true;

    remotes = [
      {
        name = "flathub";
        location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
      }
      {
        name = "GeForceNOW";
        location = "https://international.download.nvidia.com/GFNLinux/flatpak/geforcenow.flatpakrepo";
      }
    ];

    packages = [
      {
        appId = "com.nvidia.geforcenow";
        origin = "GeForceNOW";
      }
    ];

    overrides.settings = {
      global = {
        Context.sockets = [
          "wayland"
          "!x11"
          "!fallback-x11"
        ];
      };
      "com.nvidia.geforcenow".Context = {
        sockets = [ "x11" ];
      };
    };
  };
}
