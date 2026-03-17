{
  programs = {
    git = {
      enable = true;
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
