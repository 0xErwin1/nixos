{
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

      #
      # Ayu Dark color theme
      #

      # Notificaciones de error y warning
            set notification-error-bg       "#F07178"  # Error
            set notification-error-fg       "#0F1419"  # Texto sobre el error
            set notification-warning-bg     "#FBB668"  # Warning
            set notification-warning-fg     "#0F1419"  # Texto sobre el warning

      # Notificaciones generales
            set notification-bg             "#0F1419"  # Fondo principal (Ayu Dark)
            set notification-fg             "#B3B1AD"  # Texto

      # Área de autocompletado (input)
            set completion-bg               "#0F1419"  # Fondo
            set completion-fg               "#5C6773"  # Texto "comment"
            set completion-group-bg         "#0F1419"  # Fondo de grupo
            set completion-group-fg         "#5C6773"  # Texto para encabezados de grupo
            set completion-highlight-bg     "#253340"  # Resaltado de selección
            set completion-highlight-fg     "#B3B1AD"  # Texto resaltado

      # Índice (tabla de contenido) 
            set index-bg                    "#0F1419"
            set index-fg                    "#B3B1AD"
            set index-active-bg             "#253340"
            set index-active-fg             "#B3B1AD"

      # Barra de entrada y barra de estado
            set inputbar-bg                 "#0F1419"
            set inputbar-fg                 "#B3B1AD"
            set statusbar-bg                "#0F1419"
            set statusbar-fg                "#B3B1AD"

      # Colores de resaltado al buscar / seleccionar
            set highlight-color             "#36A3D9"  # Un azul/celeste
            set highlight-active-color      "#F07178"  # Un rosa/rojo

      # Colores por defecto (texto y fondo de las páginas)
            set default-bg                  "#0F1419"
            set default-fg                  "#B3B1AD"

      # Mensaje de "Loading..." cuando renderiza
            set render-loading              true
            set render-loading-fg           "#0F1419"
            set render-loading-bg           "#B3B1AD"

      #
      # Recolor mode (modo de recoloreado)
      #
            set recolor-lightcolor          "#0F1419"
            set recolor-darkcolor           "#B3B1AD"
    '';
  };
}
