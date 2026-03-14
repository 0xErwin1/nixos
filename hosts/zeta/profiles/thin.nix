{ pkgs, ... }:
{
  powerManagement.cpuFreqGovernor = "powersave";

  services.tlp.settings = {
    CPU_SCALING_GOVERNOR_ON_AC = "powersave";
    CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
    CPU_ENERGY_PERF_POLICY_ON_AC = "power";
    CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
    CPU_MIN_PERF_ON_AC = 0;
    CPU_MAX_PERF_ON_AC = 40;
    CPU_MIN_PERF_ON_BAT = 0;
    CPU_MAX_PERF_ON_BAT = 30;
    CPU_BOOST_ON_AC = 0;
    CPU_BOOST_ON_BAT = 0;
    PLATFORM_PROFILE_ON_AC = "low-power";
    PLATFORM_PROFILE_ON_BAT = "low-power";
    WIFI_PWR_ON_AC = "on";
    WIFI_PWR_ON_BAT = "on";
    USB_AUTOSUSPEND = 1;
    RUNTIME_PM_ON_AC = "auto";
    RUNTIME_PM_ON_BAT = "auto";
  };

  environment.systemPackages = with pkgs; [
    freerdp
    xrandr
    arandr
    xset
    xsetroot
    xclip
  ];
}
