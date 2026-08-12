{ pkgs, ... }:
{
  # adb only: the Android emulator publishes no linux-aarch64 binary, so the
  # androidenv SDK in hosts/globals/android.nix would be dead weight here.
  #
  # Device access needs no adbusers group or udev package: systemd tags USB
  # devices for uaccess on its own since 258, and this host runs 261.
  environment.systemPackages = [ pkgs.android-tools ];
}
