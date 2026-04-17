{ pkgs, ... }:
{
  home.packages = with pkgs; [
    gh
  ];
  programs = {
    gh-dash.enable = true;
    git = {
      enable = true;
      includes = [

      ];
      settings = {
        user = {
          name = "Ignacio Perez";
        };
        delta.enable = true;
        extraConfig = {
          push = {
            autoSetupRemote = true;
          };
        };
      };
    };
  };
}
