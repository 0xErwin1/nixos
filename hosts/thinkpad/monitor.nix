let
  eDP = {
    mode = "1920x1080";
    position = "";
    rate = "60.00";
  };
  HDMI-A-0 = {
    mode = "1920x1080";
    position = "";
    rate = "60.00";
    primary = true;
  };
  DisplayPort-0 = {
    mode = "1920x1080";
    position = "";
    rate = "75.00";
  };
  DisplayPort-1 = {
    mode = "1920x1080";
    position = "";
    rate = "75.00";
  };
in
{
  services = {
    autorandr = {
      enable = true;
      profile = {
        work = {
          config = {
            inherit eDP;
            inherit HDMI-A-0;
          };
        };
        home = {
          config = {
            inherit eDP;
            inherit HDMI-A-0;
            inherit DisplayPort-0;
            inherit DisplayPort-1;
          };
        };
        default = {
          config = {
            eDP = eDP ++ {
              primary = true;
            };
          };
        };
      };
    };
  };
}
