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

    zsh = {
      enable = true;
      autosuggestion.enable = true;
      enableCompletion = true;
      syntaxHighlighting.enable = true;
      oh-my-zsh = {
        enable = true;
        plugins = [
          "git"
          "vi-mode"
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
