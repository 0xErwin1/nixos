{ flake }:

let
  inherit (builtins)
    attrNames
    fromJSON
    length
    readFile
    ;

  lib = flake.inputs.nixpkgs.lib;

  palettes = import ../home-manager/global/theme/palettes.nix;
  ids = attrNames palettes.themes;

  configFile = file: flake.homeConfigurations."iperez@epsilon".config.xdg.configFile.${file};
  themeFile = id: name: (configFile "wl-theme/themes/${id}/${name}").text;

  # S3: Ghostty renders the theme's terminal palette, and the main config only
  # includes the state link instead of pinning a named theme.
  ghosttyLines = id: lib.splitString "\n" (themeFile id "ghostty.conf");
  expectedPalette =
    p: lib.imap0 (i: c: "palette = ${toString i}=${c}") p.terminal.ansi;
  ghosttyPalette = id: lib.filter (l: lib.hasPrefix "palette = " l) (ghosttyLines id);
  ghosttyColors =
    id:
    let
      p = palettes.themes.${id};
      lines = ghosttyLines id;
    in
    builtins.elem "background = ${p.terminal.background}" lines
    && builtins.elem "foreground = ${p.terminal.foreground}" lines
    && builtins.elem "cursor-color = ${p.terminal.cursor}" lines;
  ghosttyConfig = (configFile "ghostty/config").text;
  ghosttyIncludes =
    !(lib.hasInfix "\ntheme = " ghosttyConfig)
    && lib.count (l: lib.hasPrefix "config-file = ?" l) (lib.splitString "\n" ghosttyConfig) == 1;

  # S4: Herdr has no include, so every theme carries a complete config whose
  # colors come from that palette, plus a base matching its mode.
  herdr = id: themeFile id "herdr.toml";
  herdrNames = p: if p.mode == "light" then "catppuccin-latte" else "catppuccin-mocha";
  herdrThemed =
    id:
    let
      p = palettes.themes.${id};
      text = herdr id;
    in
    lib.hasInfix "name = \"${herdrNames p}\"" text
    && lib.hasInfix "auto_switch = false" text
    && lib.hasInfix "panel_bg = \"${p.terminal.background}\"" text
    && lib.hasInfix "text = \"${p.terminal.foreground}\"" text
    && lib.hasInfix "accent = \"${p.yellow}\"" text
    && lib.hasInfix "sidebar_bg = \"${p.panel}\"" text
    && lib.hasInfix "surface_dim = \"${p.line}\"" text;

  # S5: Zed keeps every key of settings.json and only swaps the theme name.
  settings = fromJSON (readFile ../home-manager/global/zed/settings.json);
  zed = id: fromJSON (themeFile id "zed-settings.json");
  zedNames =
    p:
    if p.family == "ayu" then
      (if p.mode == "dark" then "Ayu Mirage" else "Ayu Light")
    else
      (if p.mode == "dark" then "One Dark" else "One Light");
  zedThemed =
    id:
    let
      rendered = zed id;
    in
    rendered.theme == zedNames palettes.themes.${id}
    && length (attrNames rendered) == length (attrNames settings)
    && rendered // { theme = settings.theme; } == settings;

  # S6: the state link is opt-in, declared once, and both consumers gate on it.
  flag = flake.homeConfigurations."iperez@epsilon".config.local.wlTheme.enable;
  gated =
    file:
    lib.hasInfix "local.wlTheme.enable" (readFile ../home-manager/global/${file});
in
assert builtins.all (id: ghosttyPalette id == expectedPalette palettes.themes.${id}) ids;
assert builtins.all ghosttyColors ids;
assert ghosttyIncludes;
assert builtins.all herdrThemed ids;
assert builtins.all zedThemed ids;
assert flag && gated "herdr.nix" && gated "zed/default.nix";
{
  inherit ids;
  checked = [
    "ghostty palette and include"
    "herdr per-theme config"
    "zed per-theme settings"
    "wlTheme gating"
  ];
}
