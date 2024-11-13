{ lib, ... }:
let
  fzfDefaultOptions = [
    "--bind \"ctrl-j:down,ctrl-k:up,alt-j:preview-down,alt-k:preview-up\""
    "--height='40%'"
    "--border='none'"
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
        export NOTES_DIR="$HOME/.tabularium"
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

        fnote = "vi $(mktemp -p \"$NOTES_DIR/privatum/notae-celeres\" --suffix=.md -t notae_XXXXX)";
        vi = "nvim $1";
        "v." = "nvim .";
        ls = "eza --group-directories-first --icons";
        la = "eza --group-directories-first --icons -a";
        ll = "eza --group-directories-first --icons -l";
        cat = "bat --style=plain --color=always --paging=never";
        tree = "eza -T --icons";
        up = "docker compose up";
        upt = "docker compose -f docker-compose.test.yml up --abort-on-container-exit";
        down = "docker compose down";
        downt = "docker compose -f docker-compose.test.yml down";

        fp = "cd $(find ~/dev/personal -mindepth 2 -maxdepth 2 -type d | fzf --preview 'eza -T -a --icons -L1 {}')";
        wp = "cd $(find ~/dev/work -mindepth 2 -maxdepth 2 -type d | fzf --preview 'eza -T -a --icons -L1 {}')";
        ssh_fzf = ''ssh "$(awk "/^Host / {print \$2}" ~/.ssh/config | fzf)"'';
        docker_connect = ''docker ps >/dev/null 2>&1 || echo "Docker is not running" && docker exec -it $(docker ps --format "{{.Names}}" | fzf) /bin/sh'';

        gs = "git status -sb";
      };
    };
  };
}
