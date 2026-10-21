{
  pkgs,
  lib,
  config,
  ...
}:
let
  palettes = import ./theme/palettes.nix;
in
{
  # The colors come from the active wl-theme.
  imports = [ ./theme ];

  services.mpd = {
    enable = true;
    musicDirectory = "${config.home.homeDirectory}/Music";
    dataDir = "${config.home.homeDirectory}/.local/share/mpd";
    extraConfig = ''
      # MPD Configuration
      auto_update "yes"

      # Audio Output via PipeWire
      audio_output {
        type "pipewire"
        name "PipeWire Sound Server"
      }
    '';
  };

  programs.rmpc = {
    enable = true;
    config = ''
      #![enable(implicit_some)]
      #![enable(unwrap_newtypes)]
      #![enable(unwrap_variant_newtypes)]
      (
        address: "127.0.0.1:6600",
        password: None,
        theme: Some("wl"),
        cache_dir: Some("~/.cache/rmpc"),
        on_song_change: None,
        volume_step: 5,
        max_fps: 30,
        scrolloff: 0,
        wrap_navigation: false,
        enable_mouse: true,
        enable_config_hot_reload: true,
        status_update_interval_ms: 1000,
        select_current_song_on_change: false,
        browser_song_sort: [Disc, Track, Artist, Title],
      )
    '';
  };

  # rmpc theme, rendered once per desktop theme; `rmpc/themes/wl.ron` follows
  # the active one (wl-theme). Named colors come from the terminal palette.
  xdg.configFile = lib.mkMerge (
    [
      {
        "rmpc/themes/wl.ron".source =
          config.lib.file.mkOutOfStoreSymlink "${config.xdg.stateHome}/wl-theme/current/rmpc.ron";
      }
    ]
    ++ lib.mapAttrsToList (id: p: {
      "wl-theme/themes/${id}/rmpc.ron".text = ''
      #![enable(implicit_some)]
      #![enable(unwrap_newtypes)]
      #![enable(unwrap_variant_newtypes)]
      (
        show_song_table_header: true,
        draw_borders: true,
        browser_column_widths: [20, 38, 42],

        symbols: (
          song: "♪",
          dir: "📁",
          playlist: "📋",
          marker: "●",
          ellipsis: "...",
          song_style: None,
          dir_style: None,
          playlist_style: None,
        ),

        tab_bar: (
          active_style: (fg: "black", bg: "blue", modifiers: "Bold"),
          inactive_style: (),
        ),

        highlighted_item_style: (fg: "blue", modifiers: "Bold"),
        current_item_style: (fg: "black", bg: "blue", modifiers: "Bold"),
        borders_style: (fg: "blue"),
        highlight_border_style: (fg: "blue"),

        progress_bar: (
          symbols: ["[", "━", "▶", " ", "]"],
          track_style: (fg: "${p.muted}"),
          elapsed_style: (fg: "${p.blue}"),
          thumb_style: (fg: "${p.blue}", bg: "${p.background}"),
          use_track_when_empty: false,
        ),

        scrollbar: (
          symbols: ["│", "█", "▲", "▼"],
          track_style: (),
          ends_style: (),
          thumb_style: (fg: "blue"),
        ),

        song_table_format: [
          (
            prop: (kind: Property(Artist),
              default: (kind: Text("Unknown"))
            ),
            width: "20%",
          ),
          (
            prop: (kind: Property(Title),
              default: (kind: Text("Unknown"))
            ),
            width: "35%",
          ),
          (
            prop: (kind: Property(Album), style: (fg: "${p.foreground}"),
              default: (kind: Text("Unknown Album"), style: (fg: "${p.muted}"))
            ),
            width: "30%",
          ),
          (
            prop: (kind: Property(Duration),
              default: (kind: Text("-"))
            ),
            width: "15%",
            alignment: Right,
          ),
        ],

        header: (
          rows: [
            (
              left: [
                (kind: Text("["), style: (fg: "yellow", modifiers: "Bold")),
                (kind: Property(Status(StateV2(playing_label: "▶", paused_label: "⏸", stopped_label: "⏹"))), style: (fg: "yellow", modifiers: "Bold")),
                (kind: Text("] "), style: (fg: "yellow", modifiers: "Bold")),
                (kind: Property(Song(Artist)), style: (fg: "${p.foreground}"), default: (kind: Text("Unknown Artist"), style: (fg: "${p.muted}"))),
              ],
              center: [
                (kind: Property(Song(Title)), style: (fg: "${p.foreground}", modifiers: "Bold"), default: (kind: Text("No Song"), style: (fg: "${p.muted}", modifiers: "Bold"))),
              ],
              right: [
                (kind: Property(Widget(Volume)), style: (fg: "blue")),
                (kind: Text("  "), style: (fg: "${p.background}")),
                (kind: Property(Widget(ScanStatus)), style: (fg: "green")),
              ],
            ),
          ],
        ),

        browser_song_format: [
          (
            kind: Group([
              (kind: Property(Track)),
              (kind: Text(" ")),
            ])
          ),
          (
            kind: Group([
              (kind: Property(Artist)),
              (kind: Text(" - ")),
              (kind: Property(Title)),
            ]),
            default: (kind: Property(Filename))
          ),
        ],

        lyrics: (
          timestamp: false
        ),

        components: {},
      )
      '';
    }) palettes.themes
  );

  home.packages = with pkgs; [
    mpc
  ];
}
