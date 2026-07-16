{
  pkgs,
  lib,
  config,
  ...
}:
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
  # GPU transcription via Vulkan: whisper offloads to the GTX 1650 Ti instead of
  # the CPU (~7x real time on CPU). vulkanSupport is the nixpkgs-blessed way to
  # get the gpu-vulkan feature and its runtime deps.
  #
  # The native wgpu waveform OSD is intentionally NOT built: the Astal bar
  # (home-manager/global/bar) shows the recording indicator/waveform, so the
  # floating overlay is redundant. voxtype 0.7.2 has no config or CLI switch for
  # the OSD — the daemon always spawns voxtype-osd-native when the osd-native
  # feature is compiled in, so the only way to suppress the overlay is to leave
  # the feature out of the build entirely.
  voxtype-gpu = pkgs.voxtype.override { vulkanSupport = true; };

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
  options.local.voxtype.gpuDevice = lib.mkOption {
    type = lib.types.int;
    default = 0;
    example = 1;
    description = ''
      Vulkan device index whisper transcribes on. whisper.cpp always picks
      device 0, which on a hybrid laptop is the integrated GPU — much slower for
      inference. On epsilon the Intel iGPU enumerates as 0 and the discrete
      NVIDIA as 1, so epsilon sets this to 1; single-GPU hosts keep 0. The index
      is enumeration-order dependent (`ggml_vulkan` logs the device list on
      startup), so re-check it if the GPU set changes.
    '';
  };

  config = {
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
        # Safety cap for a recording left running (toggle mode has no auto-stop).
        # Raised from 60 s so long dictations are not cut off; note a clip this
        # long also takes proportionally long to transcribe.
        max_duration_secs = 300

        # Beep on start/stop so there is an audible cue for when capture began
        # without watching the OSD. With the XM5 the A2DP->HFP switch adds ~1 s
        # before the headset mic is actually live, so the beep is a rough "go",
        # not exact; the internal mic has no switch and is instant.
        [audio.feedback]
        enabled = true
        theme = "subtle"

        # Multilingual with auto language detection: dictation is mostly Spanish but
        # sometimes English (talking to an AI), and "auto" transcribes each utterance
        # in whichever language it was spoken. `small` is the accuracy/latency choice
        # on the NVIDIA (~7 s warm for a ~6 s clip; base is faster but coarser,
        # medium and large-v3-turbo are unusable via the Vulkan backend). gpu_device
        # selects which Vulkan device runs inference (see the option above); without
        # it whisper would sit on the slow integrated GPU.
        [whisper]
        model = "small"
        language = "auto"
        context_window_optimization = true
        gpu_device = ${toString config.local.voxtype.gpuDevice}

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

        # The native waveform OSD is disabled at the build level (the osd-native
        # feature is left out — see voxtype-gpu above), since the Astal bar shows
        # the recording indicator. voxtype 0.7.2 has no [osd] config option, so
        # there is nothing to set here.

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
        on_recording_start = true
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

        # Bias CPU toward the daemon under contention so the CPU-bound VAD step
        # (which runs before the GPU transcription and is the only part that
        # collapses under load) is not starved to a crawl by a parallel build.
        # Default weight is 100; this is a proportional share, not a guarantee —
        # a build that saturates every core can still slow VAD, just far less.
        CPUWeight = 300;
      };

      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}
