{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    pulsemixer
    easyeffects
  ];

  services.pipewire = {
    enable = true;
    alsa = {
      enable = true;
      support32Bit = true;
    };
    pulse.enable = true;
    jack.enable = true;
    wireplumber.enable = true;
    extraLv2Packages = with pkgs; [
      calf
      lsp-plugins
      mda_lv2
      rnnoise-plugin
      x42-plugins
      zam-plugins
    ];
  };
}
