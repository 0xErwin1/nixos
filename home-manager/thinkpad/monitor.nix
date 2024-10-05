let
  portableMonitorFingerprint = ''00ffffffffffff00061400000000000009210104b50000783fee91a3544c99260f5054210800d1c001010101950090408180814081c0023a801871382d403020350058c31000001a000000fc0054595045430a20202020202020000000ff0064656d6f7365742d310a203020000000fd00304b919118010a2020202020200192020321f24690010203041fe200c023097f0783010000e305c000e6060501626200023a801871382d40582c250058c31000001e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d7'';
  monitorFingerprint = ''00ffffffffffff0061a9c32301000000141e010380351d782a1f65a455509f260c5054bdcf00714f8180818c81009500950fa9c0b300023a801871382d40582c45000f252100001e000000fd00324b0f6413000a202020202020000000ff0032393230303030313532373834000000fc004d69204d6f6e69746f720a2020016d020316b149010312130414051f1067030c0010000026011d007251d01e206e285500a05a0000001e662156aa51001e30468f33000e532100001e8348801871382d4030285500a05a0000001e0e1f008051001e303020370070cf1000001e0000000000000000000000000000000000000000000000000000000000000000008c'';
  laptopFingerprint = ''00ffffffffffff0009e5de0900000000201e0104a51f1178035ff5965d5592291d5054000000010101010101010101010101010101018540802c7138a0403020360035ae1000001a000000fd00283c4a4a11010a202020202020000000fe00424f452043510a202020202020000000fe004e5631343046484d2d4e34560a00a5'';
  hdmiFingerprint = ''00ffffffffffff004c2d200d43505a5a081d010380341d782a9315a655519c27115054bfef80714f81c0810081809500a9c0b3000101023a801871382d40582c450009252100001e000000fd00324b1e5111000a202020202020000000fc00533234463335300a2020202020000000ff0048345a4d3230303633300a202001f4020311b14690041f13120365030c001000011d00bc52d01e20b828554009252100001e8c0ad090204031200c4055000925210000188c0ad08a20e02d10103e9600092521000018000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000051'';
  eDP = laptopFingerprint;
  DP-1 = monitorFingerprint;
  DP-2 = portableMonitorFingerprint;
  DisplayPort-0 = monitorFingerprint;
  DisplayPort-1 = portableMonitorFingerprint;
  HDMI-1 = hdmiFingerprint;
  HDMI-A-0 = hdmiFingerprint;
in
{
  services = {
    autorandr.enable = true;
  };

  programs.autorandr = {
    enable = true;
    profiles = {
      laptop-only = {
        fingerprint = {
          inherit eDP;
        };
        config = {
          eDP = {
            rate = "60.00";
            mode = "1920x1080";
            position = "0x0";
            primary = true;
          };
        };
      };
      laptop-dp1-dp2 = {
        fingerprint = {
          inherit eDP DP-1 DP-2;
        };
        config = {
          eDP = {
            rate = "60.00";
            mode = "1920x1080";
            position = "0x0"; # Left of DP-1
          };
          DP-1 = {
            rate = "75.00";
            mode = "1920x1080";
            position = "1920x0"; # Right of laptop
            primary = true;
          };
          DP-2 = {
            rate = "60.00";
            mode = "1920x1080";
            position = "0x1080"; # Below DP-1
          };
        };
      };

      laptop-displayports = {
        fingerprint = {
          inherit eDP DisplayPort-0 DisplayPort-1;
        };
        config = {
          eDP = {
            rate = "60.00";
            mode = "1920x1080";
            position = "0x0"; # Left of DP-1
          };
          DisplayPort-0 = {
            rate = "75.00";
            mode = "1920x1080";
            position = "1920x0"; # Right of laptop
            primary = true;
          };
          DisplayPort-1 = {
            rate = "60.00";
            mode = "1920x1080";
            position = "0x1080"; # Below DP-1
          };
        };
      };

      laptop-hdmi = {
        fingerprint = {
          inherit eDP HDMI-A-0;
        };
        config = {
          eDP = {
            rate = "60.00";
            mode = "1920x1080";
            position = "0x1080";
            primary = true;
          };
          HDMI-A-0 = {
            rate = "60.00";
            mode = "1920x1080";
            position = "0x0";
          };
        };
      };
      laptop-hdmi-dp1 = {
        fingerprint = {
          inherit eDP HDMI-1 DP-1;
        };
        config = {
          eDP = {
            rate = "60.00";
            mode = "1920x1080";
            position = "0x0";
            primary = true;
          };
          HDMI-1 = {
            rate = "60.00";
            mode = "1920x1080";
            position = "1920x0";
          };
          DP-1 = {
            rate = "60.00";
            mode = "1920x1080";
            position = "3840x0";
          };
        };
      };
    };
  };
}
