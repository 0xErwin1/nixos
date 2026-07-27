{ pkgs, ... }:
{
  home.packages = with pkgs; [
    gh
  ];
  programs = {
    gh-dash.enable = true;
    delta = {
      enable = true;
      enableGitIntegration = true;
    };
    git = {
      enable = true;
      includes = [

      ];
      settings = {
        user = {
          name = "Ignacio Perez";
        };
        push = {
          autoSetupRemote = true;
        };
      };
    };
  };
}
