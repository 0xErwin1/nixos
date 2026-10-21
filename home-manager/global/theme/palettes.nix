# Single source of the desktop palettes: the bar (SCSS), Hyprland borders,
# hyprlock and wofi all render from these values. Hex colors without alpha.
#
# Roles:
#   background  island / card background
#   panel       surface between background and grey (inset cards)
#   grey        lifted section
#   line        hairline borders (Hyprland inactive border)
#   foreground  primary text
#   muted       secondary text
#   yellow      accent, used as text and as fill
#   yellow-lite accent hover
#   on-accent   text drawn on yellow fills
#   overlay     base of translucent hovers and borders
#   terminal    kitty colors: background, foreground, cursor, selection, url
#               and the 16 ANSI colors. Ayu uses the ayu package's Mirage and
#               light terminal palettes (Mirage's black slots, near-invisible
#               on its slate ground, use its UI line and UI fg instead), and
#               Byzantium maps its semantic colors onto ANSI slots (cyan, which
#               Byzantium lacks, is the midpoint of info and success).
{
  default = "byzantium-dark";

  families = {
    ayu = {
      name = "Ayu";
      description = "Amber and sky blue";
    };

    byzantium = {
      name = "Byzantium";
      description = "Byzantine purple on graphite";
    };
  };

  themes = {
    # Ayu Mirage: the official ayu variant with a slate-blue ground, so the dark
    # Ayu theme reads apart from Byzantium's neutral graphite.
    ayu-dark = {
      family = "ayu";
      mode = "dark";
      background = "#1f2430";
      panel = "#242936";
      grey = "#282e3b";
      line = "#171b24";
      foreground = "#cccac2";
      muted = "#707a8c";
      yellow = "#ffcc66";
      yellow-lite = "#ffd98a";
      on-accent = "#735923";
      orange = "#ffa659";
      blue = "#73d0ff";
      green = "#d5ff80";
      red = "#ff6666";
      cyan = "#95e6cb";
      nix = "#5277c3";
      overlay = "#ffffff";

      terminal = {
        background = "#1f2430";
        foreground = "#cccac2";
        cursor = "#ffcc66";
        selection-background = "#274364";
        selection-foreground = "#cccac2";
        url = "#5ccfe6";
        # color0..color15
        ansi = [
          "#171b24"
          "#f06b5c"
          "#bfe76d"
          "#e6b752"
          "#3bbbf4"
          "#d09ffd"
          "#84ceb5"
          "#d2d6dc"
          "#707a8c"
          "#f39184"
          "#d5ff80"
          "#ffcd66"
          "#73d0ff"
          "#dfbfff"
          "#95e6cb"
          "#e3e6ea"
        ];
      };
    };

    ayu-light = {
      family = "ayu";
      mode = "light";
      background = "#fcfcfc";
      panel = "#f8f9fa";
      grey = "#ebeef0";
      line = "#dde1e6";
      foreground = "#5c6166";
      muted = "#828e9f";
      yellow = "#c58900";
      yellow-lite = "#d89600";
      on-accent = "#3d2a00";
      orange = "#e77316";
      blue = "#1a91cd";
      green = "#719700";
      red = "#e5474f";
      cyan = "#3b9b7c";
      nix = "#5277c3";
      overlay = "#000000";

      terminal = {
        background = "#fcfcfc";
        foreground = "#5c6166";
        cursor = "#f29718";
        selection-background = "#d7e4f6";
        selection-foreground = "#5c6166";
        url = "#22a4e6";
        # color0..color15
        ansi = [
          "#86878c"
          "#f07171"
          "#86b300"
          "#eba400"
          "#22a4e6"
          "#a37acc"
          "#4cbf99"
          "#adaeb1"
          "#939498"
          "#f07171"
          "#86b300"
          "#eba400"
          "#22a4e6"
          "#a37acc"
          "#4cbf99"
          "#c5c5c8"
        ];
      };
    };

    byzantium-dark = {
      family = "byzantium";
      mode = "dark";
      background = "#09090b";
      panel = "#100f13";
      grey = "#1a181e";
      line = "#232128";
      foreground = "#c6c3cc";
      muted = "#8e8996";
      yellow = "#d48cc8";
      yellow-lite = "#e6b8de";
      on-accent = "#09090b";
      orange = "#ffc23d";
      blue = "#6ea8ff";
      green = "#7be0a0";
      red = "#ff6b5e";
      cyan = "#b79cff";
      nix = "#5277c3";
      overlay = "#ffffff";

      terminal = {
        background = "#09090b";
        foreground = "#c6c3cc";
        cursor = "#d48cc8";
        selection-background = "#4a1b41";
        selection-foreground = "#f7f4f7";
        url = "#6ea8ff";
        # color0..color15
        ansi = [
          "#1a181e"
          "#ff6b5e"
          "#7be0a0"
          "#ffc23d"
          "#6ea8ff"
          "#d48cc8"
          "#74c4d0"
          "#c6c3cc"
          "#8e8996"
          "#ff6b5e"
          "#7be0a0"
          "#ffc23d"
          "#6ea8ff"
          "#d48cc8"
          "#74c4d0"
          "#f7f4f7"
        ];
      };
    };

    byzantium-light = {
      family = "byzantium";
      mode = "light";
      background = "#ffffff";
      panel = "#f6f4f7";
      grey = "#eeeaf0";
      line = "#e0dae3";
      foreground = "#3b3740";
      muted = "#6b6572";
      yellow = "#702963";
      yellow-lite = "#8a3a7c";
      on-accent = "#ffffff";
      orange = "#b7791f";
      blue = "#1f5fd1";
      green = "#1c7f45";
      red = "#c7362b";
      cyan = "#6b4fd8";
      nix = "#5277c3";
      overlay = "#141118";

      terminal = {
        background = "#f6f4f7";
        foreground = "#3b3740";
        cursor = "#702963";
        selection-background = "#e2d5df";
        selection-foreground = "#141118";
        url = "#1f5fd1";
        # color0..color15
        ansi = [
          "#141118"
          "#c7362b"
          "#1c7f45"
          "#b7791f"
          "#1f5fd1"
          "#702963"
          "#1e6f8b"
          "#6b6572"
          "#8e8996"
          "#c7362b"
          "#1c7f45"
          "#b7791f"
          "#1f5fd1"
          "#702963"
          "#1e6f8b"
          "#cbc4d1"
        ];
      };
    };
  };
}
