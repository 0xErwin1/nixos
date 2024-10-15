{
  programs = {
    eza.enable = true;
    bat.enable = true;
    fzf.enable = true;
    starship = {
      enable = false;
      settings = {
        add_newline = true;
      };
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
        DEVELOPMENT="$HOME/dev"
        WORK_DIR="$HOME/dev/work"
        HOULAK_DIR="$HOME/dev/work/Houlak"
        PERSONAL_DIR="$HOME/dev/personal"
        IGNIS_DIR="$HOME/dev/personal/Ignis"
        HOME_MANAGER_DIR="$HOME/.home-manager"

        function docker_connect() {
          if docker ps >/dev/null 2>&1; then
            container=$(docker ps | awk '{if (NR!=1) {print $NF}}' | fzf)

            if [[ -n $container ]]; then
              container_id=$(echo "$container" | awk -F ': ' '{print $1}')

              docker exec -it "$container_id" /bin/sh
            else
              echo "No container selected"
            fi

          else
            echo "Docker is not running"
          fi
        }
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
        theme = "af-magic";
      };
      shellAliases = {
        hwork = "cd $HOULAK_DIR";
        pdir = "cd $PERSONAL_DIR";
        idir = "cd $IGNIS_DIR";
        wdir = "cd $WORK_DIR";
        dev = "cd $DEVELOPMENT";
        hmanager = "cd $HOME_MANAGER_DIR";

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

        gs = "git status -sb";
      };
    };
  };
}
