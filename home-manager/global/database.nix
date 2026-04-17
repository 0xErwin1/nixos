{ pkgs, inputs, ... }:
{
  home.packages = with pkgs; [
    dbeaver-bin
    inputs.dbflux.packages.${pkgs.system}.default
    aws-sso-cli
    awscli2
    ssm-session-manager-plugin
  ];
}
