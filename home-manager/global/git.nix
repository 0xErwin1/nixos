{
  programs = {
    git = {
      enable = true;
      userName = "Ignacio Perez";
      includes = [
        {
          path = "~/dev/work/Houlak/.gitconfig";
          condition = "gitdit:~/dev/work/Houlak";
        }
        {
          path = "~/dev/personal/.gitconfig";
          condition = "gitdit:~/dev/personal/";
        }
        {
          path = "~/dev/personal/.gitconfig";
          condition = "gitdit:~/.home-manager/";
        }
      ];
      delta.enable = true;
    };
    gh = {
      enable = true;
    };
  };
}
