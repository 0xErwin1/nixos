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

  # Create Ayu theme for rmpc
  xdg.configFile."rmpc/themes/ayu.ron".text = ''
    #![enable(implicit_some)]
    #![enable(unwrap_newtypes)]
    #![enable(unwrap_variant_newtypes)]
    (
      header: (
        rows: [
          (columns: [
            (text: "[',('", style: (fg: "red", bg: "background")),
            (text: "$artist", style: (fg: "foreground", bg: "background")),
            (text: "' - '", style: (fg: "red", bg: "background")),
            (text: "$title", style: (fg: "foreground", bg: "background")),
            (text: "')']", style: (fg: "red", bg: "background")),
          ]),
          (columns: [
            (text: "Repeat: ", style: (fg: "comment", bg: "background")),
            (text: "$repeat", style: (fg: "yellow", bg: "background")),
            (text: " Random: ", style: (fg: "comment", bg: "background")),
            (text: "$random", style: (fg: "yellow", bg: "background")),
            (text: " Single: ", style: (fg: "comment", bg: "background")),
            (text: "$single", style: (fg: "yellow", bg: "background")),
            (text: " Consume: ", style: (fg: "comment", bg: "background")),
            (text: "$consume", style: (fg: "yellow", bg: "background")),
          ]),
        ],
      ),
      browser: (
        column_widths: [20, 30, 50],
      ),
      search: (
        column_widths: [20, 30, 50],
      ),
      playlist: (
        column_widths: [10, 35, 35, 20],
      ),
      queue: (
        column_widths: [10, 35, 35, 20],
      ),
      colors: (
        background: "#0a0e14",
        foreground: "#bfbab0",
        comment: "#6e7681",
        red: "#ff3333",
        green: "#bae67e",
        yellow: "#ffb454",
        blue: "#73d0ff",
        magenta: "#ffee99",
        cyan: "#95e6cb",
      ),
      progress_bar: (
        symbols: ["━", "━"],
        track_style: (fg: "comment", bg: "background"),
        elapsed_style: (fg: "blue", bg: "background"),
        thumb_style: (fg: "blue", bg: "background"),
      ),
      scrollbar: (
        symbols: ["│", "█", "│"],
        track_style: (fg: "comment", bg: "background"),
        thumb_style: (fg: "blue", bg: "background"),
      ),
      browser_column: (
        symbol: "│",
        style: (fg: "comment", bg: "background"),
      ),
    )
  '';

  home.packages = with pkgs; [
    mpc
  ];
}
