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
        CPU_MAX_PERF_ON_AC = 100;
        CPU_MIN_PERF_ON_BAT = 0;
        CPU_MAX_PERF_ON_BAT = 40;

        # The i5-10310U base clock is 1.7 GHz, so turbo must be on to exceed it.
        # Left uncapped it bursts to 4.4 GHz, overheats, and the firmware drops
        # it to the 400 MHz floor. Cap the ceiling at 3.0 GHz: a sustained boost
        # over base without that turbo-then-crash oscillation. Thermal headroom
        # is held by throttled below, not by the frequency cap alone.
        CPU_SCALING_MAX_FREQ_ON_AC = 3000000;
        CPU_BOOST_ON_AC = 1;
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

    # throttled owns the thermal ceiling: it trims the RAPL power limits to hold
    # the package at Trip_Temp_C, which is what actually prevents the
    # turbo -> overheat -> 400 MHz cliff. thermald is disabled in
    # hardware-configuration.nix so the two daemons do not fight over RAPL.
    # Undervolt is left at 0 — it is silicon-specific and not needed here.
    throttled.extraConfig = ''
      [GENERAL]
      Enabled: True
      Sysfs_Power_Path: /sys/class/power_supply/AC*/online
      Autoreload: True

      [BATTERY]
      Update_Rate_s: 5
      PL1_Tdp_W: 15
      PL1_Duration_s: 28
      PL2_Tdp_W: 20
      PL2_Duration_S: 0.002
      Trip_Temp_C: 80
      cTDP: 0
      Disable_BDPROCHOT: False

      [AC]
      Update_Rate_s: 1
      PL1_Tdp_W: 25
      PL1_Duration_s: 28
      PL2_Tdp_W: 35
      PL2_Duration_S: 0.002
      Trip_Temp_C: 85
      HWP_Mode: True
      cTDP: 0
      Disable_BDPROCHOT: False

      [UNDERVOLT.BATTERY]
      CORE: 0
      GPU: 0
      CACHE: 0
      UNCORE: 0
      ANALOGIO: 0

      [UNDERVOLT.AC]
      CORE: 0
      GPU: 0
      CACHE: 0
      UNCORE: 0
      ANALOGIO: 0
    '';

    logind.lidSwitch = "suspend";
  };
}
