{ pkgs, ... }:
{
  services.mpd = {
    enable = true;
    musicDirectory = "~/.music";
    extraConfig = ''
      # MPD Configuration
      auto_update "yes"
      
      # Audio Output via PipeWire
      audio_output {
        type "pipewire"
        name "PipeWire Sound Server"
      }
      
      # Playlist directory
      playlist_directory "~/.config/mpd/playlists"
      
      # Database and logs
      db_file "~/.config/mpd/database"
      log_file "~/.config/mpd/log"
      
      # State and sticker files
      state_file "~/.config/mpd/state"
      sticker_file "~/.config/mpd/sticker.sql"
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
        theme: Some("ayu"),
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

  # Create Ayu theme for rmpc - Minimal but complete
  xdg.configFile."rmpc/themes/ayu.ron".text = ''
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
        track_style: (fg: "#6e7681"),
        elapsed_style: (fg: "#73d0ff"),
        thumb_style: (fg: "#73d0ff", bg: "#0a0e14"),
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
          prop: (kind: Property(Album), style: (fg: "#bfbab0"),
            default: (kind: Text("Unknown Album"), style: (fg: "#6e7681"))
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
              (kind: Property(Song(Artist)), style: (fg: "#bfbab0"), default: (kind: Text("Unknown Artist"), style: (fg: "#6e7681"))),
            ],
            center: [
              (kind: Property(Song(Title)), style: (fg: "#bfbab0", modifiers: "Bold"), default: (kind: Text("No Song"), style: (fg: "#6e7681", modifiers: "Bold"))),
            ],
            right: [
              (kind: Property(Widget(Volume)), style: (fg: "blue")),
              (kind: Text("  "), style: (fg: "#0a0e14")),
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

  home.packages = with pkgs; [
    mpc
  ];
}
