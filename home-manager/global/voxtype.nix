{ pkgs, ... }:
# Voice-to-text dictation daemon.
#
#   - `hotkey.enabled` stays false: voxtype's built-in hotkey uses evdev, which
#     needs 'input' group membership and cannot see Wayland focus. Recording is
#     driven instead by a Hyprland bind calling `voxtype record toggle`.
#   - The whisper and Silero VAD models are large binaries that voxtype would
#     otherwise fetch imperatively at runtime into ~/.local/share/voxtype/models.
#     They are pinned here with fetchurl and linked into that directory so the
#     model set is reproducible and part of the closure instead of hand-downloaded.
let
  # Runtime libraries the OSD frontend dlopen's: smithay-client-toolkit loads
  # libwayland-client at runtime, and wgpu loads libvulkan/libGL. None are in
  # the binary's DT_NEEDED, so they have to be forced onto its library path.
  osdRuntimeLibs = with pkgs; [
    wayland
    libxkbcommon
    libGL
    vulkan-loader
  ];

  # nixpkgs builds voxtype CPU-only and without any OSD frontend. This override:
  #   - vulkanSupport: whisper offloads to the GTX 1650 Ti instead of the CPU
  #     (~7x real time on CPU).
  #   - osd-native: builds the SCTK + wgpu + egui waveform overlay. nixpkgs does
  #     not expose it. The feature must be forced onto BOTH cargoBuildFeatures and
  #     cargoCheckFeatures directly: buildRustPackage derives those from the
  #     original buildFeatures before overrideAttrs runs, so setting buildFeatures
  #     alone silently leaves the frontend out of the cargo invocation.
  #   - postInstall: buildRustPackage's installer only copies binaries it sees
  #     without the feature enabled, so voxtype-osd-native has to be installed and
  #     wrapped by hand.
  voxtype-gpu = (pkgs.voxtype.override { vulkanSupport = true; }).overrideAttrs (old: {
    buildFeatures = (old.buildFeatures or [ ]) ++ [ "osd-native" ];
    cargoBuildFeatures = [
      "gpu-vulkan"
      "osd-native"
    ];
    cargoCheckFeatures = [
      "gpu-vulkan"
      "osd-native"
    ];
    buildInputs = old.buildInputs ++ osdRuntimeLibs ++ [ pkgs.wayland-protocols ];
    postInstall = (old.postInstall or "") + ''
      install -Dm755 "$(ls target/*/release/voxtype-osd-native)" $out/bin/voxtype-osd-native
      wrapProgram $out/bin/voxtype-osd-native \
        --prefix LD_LIBRARY_PATH : ${pkgs.lib.makeLibraryPath osdRuntimeLibs}
    '';
  });

  whisperModel = pkgs.fetchurl {
    url = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small.bin";
    hash = "sha256-G+OpsgY4Z7k35k4ux0gzZKeZF+FX+pjF2UtcH//qmHs=";
  };

  vadModel = pkgs.fetchurl {
    url = "https://huggingface.co/ggml-org/whisper-vad/resolve/main/ggml-silero-v6.2.0.bin";
    hash = "sha256-KqJpt4XutTqCmDogUB3ffB2cSOM6tjpBORrGyff7aYc=";
  };
in
{
  home.packages = [
    voxtype-gpu
    pkgs.wtype
  ];

  xdg.dataFile = {
    "voxtype/models/ggml-small.bin".source = whisperModel;
    "voxtype/models/ggml-silero-vad.bin".source = vadModel;
  };

  xdg.configFile."voxtype/config.toml" = {
    force = true;
    text = ''
      state_file = "auto"

      [hotkey]
      enabled = false

      # "default" follows PipeWire's default source. When the XM5 is connected
      # that is its mic, so recording triggers the WirePlumber autoswitch to HFP
      # and dictation is captured through the headset (mSBC gives it 16 kHz, see
      # hosts/globals/pipewire.nix). With only the wired FiiO (no mic) or nothing
      # connected, the default source is the internal ThinkPad array instead.
      #
      # max_duration_secs has no default in the parser: omitting it makes the
      # whole config fail to load.
      [audio]
      device = "default"
      sample_rate = 16000
      max_duration_secs = 60

      # Multilingual with auto language detection: dictation is mostly Spanish but
      # sometimes English (talking to an AI), and "auto" transcribes each utterance
      # in whichever language it was spoken. `small` is the accuracy/latency choice
      # for this GPU: it transcribes a ~6 s clip in ~8 s (base is ~3 s but coarser,
      # medium ~23 s and large-v3-turbo ~40 s are unusable via the Vulkan backend).
      [whisper]
      model = "small"
      language = "auto"
      context_window_optimization = true

      # Without voice-activity detection Whisper hallucinates a stock phrase from
      # near-silence (it will "transcribe" a recording with no speech). Silero VAD
      # gates transcription on actual speech. threshold is raised above the 0.5
      # default so ambient room noise does not read as speech, and a minimum
      # speech duration rejects short blips.
      [vad]
      enabled = true
      backend = "whisper"
      threshold = 0.7
      min_speech_duration_ms = 250

      # Floating waveform overlay shown while recording — the recording indicator
      # that toggle mode needs. frontend = native is the SCTK + wgpu build wired
      # up above; the gtk4 default is not built.
      [osd]
      enabled = true
      frontend = "native"

      # paste mode copies the transcript to the clipboard and then fires the paste
      # keystroke. If a text field is focused the text lands there; if not, it
      # stays on the clipboard to paste by hand. type mode would silently drop the
      # text with no focus, because wtype "succeeds" sending keys into the void and
      # the clipboard fallback never triggers. restore_clipboard = false keeps the
      # transcript on the clipboard instead of restoring the previous contents, so
      # it survives either way. paste_keys uses ctrl+shift+v: that pastes in kitty
      # (where the agents run) and in browsers; a plain GTK entry may ignore it,
      # but then the clipboard still holds the text.
      [output]
      mode = "paste"
      paste_keys = "ctrl+shift+v"
      restore_clipboard = false
      fallback_to_clipboard = true

      [output.notification]
      on_transcription = true
    '';
  };

  # The daemon opens the capture device on startup, so PipeWire has to be up
  # first or it binds to no source and every recording comes back empty.
  systemd.user.services.voxtype = {
    Unit = {
      Description = "Voxtype voice-to-text daemon";
      After = [
        "pipewire.service"
        "pipewire-pulse.service"
        "graphical-session.target"
      ];
      Wants = [
        "pipewire.service"
        "pipewire-pulse.service"
      ];
      PartOf = [ "graphical-session.target" ];
    };

    Service = {
      ExecStart = "${voxtype-gpu}/bin/voxtype daemon";
      Restart = "on-failure";
    };

    Install.WantedBy = [ "graphical-session.target" ];
  };
}
