{ pkgs, ... }:
let
  tmuxAyuTheme = pkgs.fetchFromGitHub {
    owner = "TechnicalDC";
    repo = "tmux-ayu-theme";
    rev = "2ddd8537e2f98cc760c1e2ded4bcbc62a20b8f42";
    sha256 = "sha256-/MLP0tE5wSQ/Vcnruy34bQ5kes6AoT0zH2urBcetiq0=";
  };
in
{
  home.packages = with pkgs; [ tmux ];
  programs.tmux = {
    shortcut = "a";
    enable = true;
    keyMode = "vi";
    mouse = true;
    prefix = "C-a";
    extraConfig = ''
      set -g default-terminal "xterm-256color"
      set -ga terminal-overrides ",xterm-256color:Tc"
      set -g base-index 1
      set -g pane-base-index 1
      set-window-option -g pane-base-index 1
      set-option -g renumber-windows on

      set -g mode-keys vi
      set-window-option -g mode-keys vi
      bind-key -T copy-mode-vi v send-keys -X begin-selection
      bind-key -T copy-mode-vi C-v send-keys -X rectangle-toggle
      bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel

      set -g xterm-keys on

      unbind C-j
      unbind C-k

      bind-key -n C-j send-keys C-j
      bind-key -n C-k send-keys C-k
      unbind c
      unbind %
      unbind '"'
      bind % split-window -h -c "$HOME"
      bind '"' split-window -v -c "$HOME"
      bind c new-window -c "$HOME"

      unbind f
      unbind C-w

      bind -n M-h previous-window
      bind -n M-l next-window

      set -g status-position top

      TMUX_FZF_OPTIONS="-w 70% -h 70% -m"
      TMUX_FZF_LAUNCH_KEY="C-f"
    '';
    plugins = [
      pkgs.tmuxPlugins.resurrect
      pkgs.tmuxPlugins.continuum
      pkgs.tmuxPlugins.sensible
      pkgs.tmuxPlugins.vim-tmux-navigator
      pkgs.tmuxPlugins.tmux-fzf
      pkgs.tmuxPlugins.yank
      (pkgs.tmuxPlugins.mkTmuxPlugin {
        pluginName = "ayu-theme";
        version = "main";
        rtpFilePath = "tmux-ayu-theme.tmux";
        src = tmuxAyuTheme;
      })
    ];
  };
}
