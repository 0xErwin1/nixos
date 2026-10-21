{ config, ... }:
{
  # The colors come from the active wl-theme.
  imports = [ ./theme ];

  programs.zathura = {
    enable = true;
    extraConfig = ''
            set scroll-page-aware true
            set scroll-full-overlap 0.01
            set scroll-step 100
            set selection-clipboard clipboard
            set window-title-basename "true"
            set adjust-open width
            set recolor true
            set statusbar-h-padding 1
            set statusbar-v-padding 0
            set guioptions none

            set font "FiraCode Nerd Font 12"

            map <C-+> zoom in
            map <C-=> zoom in

            map <C--> zoom out

            set render-loading              true

            # Colors follow the active desktop theme (wl-theme).
            include ${config.xdg.stateHome}/wl-theme/current/zathurarc
    '';
  };
}
