{
  programs = {
    librewolf = {
      enable = true;
    };
    firefox = {
      enable = true;
      profiles = {
        profile_0 = {
          id = 0;
          name = "profile_0";
          isDefault = true;
          userChrome = ''

          '';
        };
      };
    };
  };

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "default-web-browser" = [ "librewolf.desktop" ];
      "text/html" = [ "librewolf.desktop" ];
      "x-scheme-handler/http" = [ "librewolf.desktop" ];
      "x-scheme-handler/https" = [ "librewolf.desktop" ];
      "x-scheme-handler/about" = [ "librewolf.desktop" ];
      "x-scheme-handler/unknown" = [ "librewolf.desktop" ];
    };
  };
}
