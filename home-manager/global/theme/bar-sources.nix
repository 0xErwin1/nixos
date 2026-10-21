# Bar theme sources, generated from ./palettes.nix and copied into the bar's
# `src/themes/` before `ags bundle`:
#
#   _palette.scss  every role as a `!default` variable (default theme values);
#                  the body (`style.scss`) and its partials `@use` it.
#   <id>.scss      one entry per theme: configures the palette module, then
#                  loads the preview colors and the body. ags compiles each
#                  imported .scss with dart-sass on its own, so each entry
#                  becomes one complete stylesheet string.
#   _previews.scss literal colors of every theme for the Appearance panel's
#                  previews, so they render the same under any active theme.
#   index.ts       theme metadata plus the compiled CSS of every theme.
{ pkgs, lib }:
let
  palettes = import ./palettes.nix;

  ids = builtins.attrNames palettes.themes;

  roles = [
    "background"
    "panel"
    "grey"
    "line"
    "foreground"
    "muted"
    "yellow"
    "yellow-lite"
    "on-accent"
    "orange"
    "blue"
    "green"
    "red"
    "cyan"
    "nix"
    "overlay"
  ];

  defaultPalette = palettes.themes.${palettes.default};

  paletteScss = lib.concatMapStrings (
    role: "\$${role}: ${defaultPalette.${role}} !default;\n"
  ) roles;

  entryScss =
    id:
    let
      p = palettes.themes.${id};
      config = lib.concatMapStringsSep ",\n" (role: "  \$${role}: ${p.${role}}") roles;
    in
    ''
      @use "palette" with (
      ${config}
      );
      @use "previews";
      @use "../style";
    '';

  previewScss =
    id:
    let
      p = palettes.themes.${id};
    in
    ''
      .pv-${id} { background-color: ${p.grey}; }
      .pv-${id} .pv-strip { background-color: ${p.background}; }
      .pv-${id} .pv-dot { background-color: ${p.muted}; }
      .pv-${id} .pv-pill { background-color: ${p.yellow}; }
      .pv-${id} .pv-window { background-color: ${p.background}; border-color: ${p.line}; }
      .pv-${id} .pv-title { background-color: ${p.foreground}; }
      .pv-${id} .pv-line { background-color: ${p.muted}; }
      .pv-${id} .pv-swatch-0 { background-color: ${p.blue}; }
      .pv-${id} .pv-swatch-1 { background-color: ${p.green}; }
      .pv-${id} .pv-swatch-2 { background-color: ${p.orange}; }
      .pv-${id} .pv-swatch-3 { background-color: ${p.red}; }
      .pv-${id} .pv-button { background-color: ${p.yellow}; }
    '';

  cssIdent = id: "css_" + lib.replaceStrings [ "-" ] [ "_" ] id;

  themeList = map (id: {
    inherit id;
    inherit (palettes.themes.${id}) family mode;
    colors = lib.genAttrs roles (role: palettes.themes.${id}.${role});
  }) ids;

  indexTs = ''
    // Generated from home-manager/global/theme/palettes.nix by the bar derivation.
    ${lib.concatMapStrings (id: "import ${cssIdent id} from \"./${id}.scss\";\n") ids}
    export const DEFAULT_THEME = ${builtins.toJSON palettes.default};

    export const FAMILIES = ${builtins.toJSON palettes.families} as const;

    export const THEMES = ${builtins.toJSON themeList} as const;

    export const THEME_CSS: Record<string, string> = {
    ${lib.concatMapStrings (id: "  ${builtins.toJSON id}: ${cssIdent id},\n") ids}};
  '';
in
pkgs.runCommand "wl-bar-theme-sources"
  {
    passAsFile = [
      "paletteScss"
      "previewsScss"
      "indexTs"
    ];
    inherit paletteScss indexTs;
    previewsScss = lib.concatMapStrings previewScss ids;
  }
  ''
    mkdir -p $out
    cp "$paletteScssPath" $out/_palette.scss
    cp "$previewsScssPath" $out/_previews.scss
    cp "$indexTsPath" $out/index.ts
    ${lib.concatMapStrings (id: ''
      cp ${pkgs.writeText "${id}.scss" (entryScss id)} $out/${id}.scss
    '') ids}
  ''
