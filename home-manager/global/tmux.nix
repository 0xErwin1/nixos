{ pkgs, ... }:
let
  tmuxAyuThemeScript = pkgs.writeShellScript "tmux-ayu-theme.tmux" ''
    ayu_black="#101521"
    ayu_blue="#5CCFE6"
    ayu_yellow="#E6B450"
    ayu_red="#F28779"
    ayu_white="#CBCCC6"
    ayu_green="#BAE67E"
    ayu_visual_grey="#607080"
    ayu_comment_grey="#5C6773"

    get() {
       local option=$1
       local default_value=$2
       local option_value="$(tmux show-option -gqv "$option")"

       if [ -z "$option_value" ]; then
          echo "$default_value"
       else
          echo "$option_value"
       fi
    }

    set() {
       local option=$1
       local value=$2
       tmux set-option -gq "$option" "$value"
    }

    setw() {
       local option=$1
       local value=$2
       tmux set-window-option -gq "$option" "$value"
    }

    set "status" "on"
    set "status-justify" "left"

    set "status-left-length" "100"
    set "status-right-length" "100"
    set "status-right-attr" "none"

    set "message-fg" "$ayu_white"
    set "message-bg" "$ayu_black"

    set "message-command-fg" "$ayu_white"
    set "message-command-bg" "$ayu_black"

    set "status-attr" "none"
    set "status-left-attr" "none"

    setw "window-status-fg" "$ayu_black"
    setw "window-status-bg" "$ayu_black"
    setw "window-status-attr" "none"

    setw "window-status-activity-bg" "$ayu_black"
    setw "window-status-activity-fg" "$ayu_black"
    setw "window-status-activity-attr" "none"

    setw "window-status-separator" ""

    set "window-style" "fg=$ayu_comment_grey"
    set "window-active-style" "fg=$ayu_white"

    set "pane-border-fg" "$ayu_white"
    set "pane-border-bg" "$ayu_black"
    set "pane-active-border-fg" "$ayu_green"
    set "pane-active-border-bg" "$ayu_black"

    set "display-panes-active-colour" "$ayu_yellow"
    set "display-panes-colour" "$ayu_blue"

    set "status-bg" "$ayu_black"
    set "status-fg" "$ayu_white"

    set "@prefix_highlight_fg" "$ayu_black"
    set "@prefix_highlight_bg" "$ayu_green"
    set "@prefix_highlight_copy_mode_attr" "fg=$ayu_black,bg=$ayu_green"
    set "@prefix_highlight_output_prefix" "  "

    status_widgets=$(get "@ayu_widgets")
    time_format=$(get "@ayu_time_format" "%R")
    date_format=$(get "@ayu_date_format" "%d.%m.%Y")

    set "status-right" "#[fg=$ayu_white,bg=$ayu_black,nounderscore,noitalics]  ''${time_format}    ''${date_format} #[fg=$ayu_visual_grey,bg=$ayu_black]#[fg=$ayu_visual_grey,bg=$ayu_visual_grey]#[fg=$ayu_white, bg=$ayu_visual_grey]''${status_widgets} #[fg=$ayu_green,bg=$ayu_visual_grey,nobold,nounderscore,noitalics]#[fg=$ayu_black,bg=$ayu_green,bold] #h "
    set "status-left" "#[fg=$ayu_black,bg=$ayu_green,bold]   #S #{prefix_highlight}#[fg=$ayu_green,bg=$ayu_black,nobold,nounderscore,noitalics]"

    set "window-status-format" "#[fg=$ayu_black,bg=$ayu_black,nobold,nounderscore,noitalics]#[fg=$ayu_white,bg=$ayu_black] #I  #W #[fg=$ayu_black,bg=$ayu_black,nobold,nounderscore,noitalics]"
    set "window-status-current-format" "#[fg=$ayu_black,bg=$ayu_yellow,nobold,nounderscore,noitalics]#[fg=$ayu_black,bg=$ayu_yellow,nobold] #I  #W #[fg=$ayu_yellow,bg=$ayu_black,nobold,nounderscore,noitalics]"
  '';

  tmuxConfig =
    builtins.replaceStrings
      [
        "run '~/.tmux/plugins/tpm/tpm'"
        "set -g @plugin 'TechnicalDC/tmux-ayu-theme'"
      ]
      [
        ""
        ""
      ]
      (builtins.readFile ../../dotfiles/.config/tmux/tmux.conf);
in
{
  programs.tmux = {
    shortcut = "a";
    enable = true;
    keyMode = "vi";
    mouse = true;
    prefix = "C-Space";

    plugins = [
      pkgs.tmuxPlugins.resurrect
      pkgs.tmuxPlugins.continuum
      pkgs.tmuxPlugins.sensible
      pkgs.tmuxPlugins.vim-tmux-navigator
      pkgs.tmuxPlugins.tmux-fzf
      pkgs.tmuxPlugins.yank
    ];

    extraConfig = ''
      ${tmuxConfig}

      run-shell ${tmuxAyuThemeScript}
    '';
  };
}
