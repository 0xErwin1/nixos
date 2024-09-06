{ pkgs, ... }:
{
  home.packages = with pkgs; [ tmux ];
  programs.tmux = {
    shortcut = "a";
    extraConfig = ''
      set -g default-terminal "tmux-256color"
      set -ga terminal-overrides ",xterm-256color:Tc"

      set -g mouse on

      unbind C-b
      set -g prefix C-a
      bind C-a send-prefix

      set -g base-index 1
      set -g pane-base-index 1
      set-window-option -g pane-base-index 1
      set-option -g renumber-windows on

      set -g mode-keys vi
      set-window-option -g mode-keys vi
      bind-key -T copy-mode-vi v send-keys -X begin-selection
      bind-key -T copy-mode-vi C-v send-keys -X rectangle-toggle
      bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel

      unbind f
      unbind C-w

      bind -n M-h previous-window
      bind -n M-l next-window

      set -g @plugin 'TechnicalDC/tmux-ayu-theme'
      set -g status-position top

      TMUX_FZF_OPTIONS="-w 70% -h 70% -m"
      TMUX_FZF_LAUNCH_KEY="f"
    '';
    plugins = with pkgs.tmuxPlugins; [
      tpm
      resurrect
      continuum
      sensible
      vim-tmux-navigator
      fzf
      yank
    ];
  };
}
