{ pkgs, ... }:

let
  androidComposition = pkgs.androidenv.composeAndroidPackages {
    includeEmulator = "if-supported";
    includeSystemImages = true;
    systemImageTypes = [ "google_apis" ];
    abiVersions = [ "x86_64" ];
    extraLicenses = [
      "android-sdk-preview-license"
      "google-gdk-license"
      "intel-android-extra-license"
      "intel-android-sysimage-license"
    ];
  };

  androidSdk = androidComposition.androidsdk;
in
{
  nixpkgs.config.android_sdk.accept_license = true;

  users.users.iperez.extraGroups = [ "kvm" ];

  environment.systemPackages = [
    androidSdk
    androidComposition.platform-tools
    pkgs.android-tools
  ];

  environment.sessionVariables = {
    ANDROID_HOME = "${androidSdk}/libexec/android-sdk";
    ANDROID_SDK_ROOT = "${androidSdk}/libexec/android-sdk";
  };
}
