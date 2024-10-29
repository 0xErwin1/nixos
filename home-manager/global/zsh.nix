{ lib, ... }:
let
  fzfDefaultOptions = [
    # "--height='40%'"
    # "--border='none'"
    # "--color=fg:#d0d0d0,fg+:#d0d0d0,bg:#121212,bg+:#262626"
    # "--color=hl:#5f87af,hl+:#5fd7ff,info:#afaf87,marker:#87ff00"
    # "--color=prompt:#d7005f,spinner:#af5fff,pointer:#af5fff,header:#87afaf"
    # "--color=border:#262626,label:#aeaeae,query:#d9d9d9"
  ];
  fzfDefaultCommand = "fd --type f --hidden --follow --exclude .git";
in
{
  imports = [ ./starship.nix ];
  programs = {
    eza.enable = true;
    bat.enable = true;
    fzf = {
      enable = true;
      enableZshIntegration = true;
      defaultOptions = fzfDefaultOptions;
      defaultCommand = fzfDefaultCommand;
    };
    readline = {
      enable = true;
      extraConfig = ''
        set bell-style none
      '';
    };

    zsh = {
      enable = true;
      autosuggestion.enable = true;
      enableCompletion = true;
      syntaxHighlighting.enable = true;
      initExtra = ''
        export FZF_DEFAULTS_OPTS="${lib.concatStringsSep " " fzfDefaultOptions}"
        export DEVELOPMENT="$HOME/dev"
        export WORK_DIR="$HOME/dev/work"
        export HOULAK_DIR="$HOME/dev/work/Houlak"
        export PERSONAL_DIR="$HOME/dev/personal"
        export IGNIS_DIR="$HOME/dev/personal/Ignis"
        export HOME_MANAGER_DIR="$HOME/.home-manager"
        export NOTES_DIR="$HOME/.notes"
      '';
      oh-my-zsh = {
        enable = true;
        plugins = [
          "git"
          "fzf"
          "gh"
          "colorize"
          "urltools"
          "taskwarrior"
          "direnv"
          "fnm"
          "pyenv"
          "jenv"
          "node"
          "sdk"
          "rust"
        ];
      };
      shellAliases = {
        hwork = "cd $HOULAK_DIR";
        pdir = "cd $PERSONAL_DIR";
        idir = "cd $IGNIS_DIR";
        wdir = "cd $WORK_DIR";
        dev = "cd $DEVELOPMENT";
        hmanager = "cd $HOME_MANAGER_DIR";
        notes = "cd $NOTES_DIR";

        fnote = "vi $(mktemp -p $NOTES_DIR)";
        vi = "nvim $1";
        "v." = "nvim .";
        ls = "eza --group-directories-first --icons";
        la = "eza --group-directories-first --icons -a";
        ll = "eza --group-directories-first --icons -l";
        tree = "eza -T --icons";
        up = "docker compose up";
        upt = "docker compose -f docker-compose.test.yml up --abort-on-container-exit";
        down = "docker compose down";
        downt = "docker compose -f docker-compose.test.yml down";

        ssh_fzf = ''ssh "$(awk "/^Host / {print \$2}" ~/.ssh/config | fzf)"'';
        docker_connect = ''docker ps >/dev/null 2>&1 || echo "Docker is not running" && docker exec -it $(docker ps --format "{{.Names}}" | fzf) /bin/sh'';

        gs = "git status -sb";
      };
    };
  };
}
