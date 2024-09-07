{ pkgs, inputs, ... }:
{
  imports = [
    ../global
    ../global/kitty.nix
  ];
  targets.genericLinux.enable = true;

  home = {
    enableNixpkgsReleaseCheck = false;
    username = "iperez";
    homeDirectory = "/home/iperez";
    stateVersion = "24.05";
    packages = [
      pkgs.eza
      pkgs.zsh
      pkgs.curl
      pkgs.wget
      pkgs.btop
      pkgs.firefox
      pkgs.delta
    ];
    sessionVariables = {
      EDITOR = "nvim";
    };
  };

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };

  programs = {
    home-manager.enable = true;
    git = {
      enable = true;
      userName = "Ignacio Perez";
    };
  };

}
