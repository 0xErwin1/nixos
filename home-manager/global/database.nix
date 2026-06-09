{ pkgs, ... }:
{
  home.packages = with pkgs; [
    dbeaver-bin
    dbflux
    dbflux-nightly
    aws-sso-cli
    awscli2
    ssm-session-manager-plugin
  ];
}
