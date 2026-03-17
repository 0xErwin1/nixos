{ ... }:
{
  powerManagement.cpuFreqGovernor = "powersave";

  services = {
    tlp = {
      enable = true;
      settings = {
        CPU_SCALING_GOVERNOR_ON_AC = "performance";
        CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

        CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
        CPU_ENERGY_PERF_POLICY_ON_BAT = "balance_power";

        CPU_MIN_PERF_ON_AC = 0;
        CPU_MAX_PERF_ON_AC = 65;
        CPU_MIN_PERF_ON_BAT = 0;
        CPU_MAX_PERF_ON_BAT = 40;

        CPU_BOOST_ON_AC = 0;
        CPU_BOOST_ON_BAT = 0;

        PLATFORM_PROFILE_ON_AC = "performance";
        PLATFORM_PROFILE_ON_BAT = "balanced";

        WIFI_PWR_ON_AC = "on";
        WIFI_PWR_ON_BAT = "on";
        USB_AUTOSUSPEND = 1;
        RUNTIME_PM_ON_AC = "auto";
        RUNTIME_PM_ON_BAT = "auto";
      };
    };

    thermald.enable = true;
    logind.lidSwitch = "suspend";
  };
}
