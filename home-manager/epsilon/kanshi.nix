{
  services.kanshi = {
    enable = true;

    settings = [
      {
        profile = {
          name = "mobile";
          outputs = [
            {
              criteria = "eDP-1";
              scale = 1.0;
              position = "0,0";
            }
          ];
        };
      }
      {
        profile = {
          name = "dock-dp";
          outputs = [
            {
              criteria = "eDP-1";
              scale = 1.0;
              position = "0,0";
            }
            {
              criteria = "DP-1";
              scale = 1.0;
              position = "0,1080";
            }
          ];
        };
      }
    ];
  };
}
