{
  programs = {
    git = {
      enable = true;
      userName = "Ignacio Perez";
      includes = [
        {
          path = "~/dev/personal/.gitconfig";
          condition = "gitdit:~/dev/work/";
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
