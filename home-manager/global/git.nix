{
  programs = {
    git = {
      enable = true;
      userName = "Ignacio Perez";
      includes = [
        {
          path = "~/dev/work/Houlak/.gitconfig";
          condition = "gitdir:~/dev/work/Houlak/";
        }
        {
          path = "~/dev/personal/.gitconfig";
          condition = "gitdir:~/dev/personal/";
        }
        {
          path = "~/dev/personal/.gitconfig";
          condition = "gitdir:~/.config/home-manager/";
        }
      ];
      delta.enable = true;
      extraConfig = {
        push = {
          autoSetupRemote = true;
        };
      };
    };
  };
}
