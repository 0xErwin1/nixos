{
  imports = [
    ../global/zsh.nix
    ../global/git.nix
    ../global/tmux.nix
    ../global/direnv.nix
    ../global/herdr.nix
    ../global/neovim.nix
    ../global/ai-headless.nix
    ../global/headless-utilities.nix
    ../global/headless-cpu-slices.nix
    ./clip.nix
    ./fixdisplay.nix
    ./herdr-server.nix
    ./browserless.nix
  ];
}
