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
      ];
      delta.enable = true;
    };
    gh = {
      enable = true;
    };
  };
}
