{ pkgs, inputs, ... }:
{
  home.packages = with pkgs; [
    dbeaver-bin
    dbflux
    aws-sso-cli
    awscli2
    ssm-session-manager-plugin
  ];
}
