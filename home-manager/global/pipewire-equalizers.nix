# Per-device output equalizers, implemented as PipeWire filter-chains.
#
# These used to be EasyEffects presets. EasyEffects cannot be used here: it
# permanently holds a capture stream open on the Bluetooth microphone loopback
# source and re-routes every capture client onto its own `easyeffects_source`,
# which carries no `node.link-group`. WirePlumber's autoswitch script
# (scripts/device/autoswitch-bluetooth-profile.lua) walks that property to find
# the loopback source behind a capture stream, so with EasyEffects running it
# never recognises a capture client on the headset and never switches the card
# to `headset-head-unit`. The microphone is then permanently dead in calls.
#
# A filter-chain smart filter processes playback only, creates no capture
# stream, and therefore leaves the autoswitch intact. Do not reintroduce
# EasyEffects to get the equalizers back.
#
# Band gains/frequencies/Q come from the original EasyEffects presets. Note the
# math is not bit-identical: EasyEffects runs its bands in "APO (DR)" mode while
# the `param_eq` builtin uses RBJ biquads, so the shelves in particular are
# close but not exact.
{ lib, ... }:
let
  # Builds one filter-chain config from a device spec. `preampMult` is the
  # preamp expressed as a linear multiplier (10 ^ (dB / 20)); Nix has no float
  # exponentiation, so it is precomputed. `smartTarget` is ANDed key-by-key by
  # WirePlumber against candidate sinks to decide where the filter attaches.
  mkEqualizer =
    {
      id,
      description,
      preampMult,
      bands,
      smartTarget,
    }:
    let
      filterName = "filter.sink.${id}-equalizer";

      preamp = channel: {
        type = "builtin";
        name = "preamp_${channel}";
        label = "linear";
        control = {
          "Mult" = preampMult;
          "Add" = 0.0;
        };
      };

      filterGraph = {
        nodes = [
          (preamp "fl")
          (preamp "fr")
          {
            type = "builtin";
            name = "eq";
            label = "param_eq";
            config = {
              filters = bands;
            };
          }
        ];

        links = [
          {
            output = "preamp_fl:Out";
            input = "eq:In 1";
          }
          {
            output = "preamp_fr:Out";
            input = "eq:In 2";
          }
        ];

        inputs = [
          "preamp_fl:In"
          "preamp_fr:In"
        ];

        outputs = [
          "eq:Out 1"
          "eq:Out 2"
        ];
      };
    in
    {
      "context.modules" = [
        {
          name = "libpipewire-module-filter-chain";
          args = {
            "node.name" = filterName;
            "node.description" = description;
            "media.name" = description;

            "filter.graph" = filterGraph;

            "audio.channels" = 2;
            "audio.position" = [
              "FL"
              "FR"
            ];

            "capture.props" = {
              "media.class" = "Audio/Sink";

              "filter.smart" = true;
              "filter.smart.name" = filterName;
              "filter.smart.target" = smartTarget;
            };

            "playback.props" = {
              "node.passive" = true;
              "media.role" = "DSP";

              # Without these, WirePlumber falls back to the default sink whenever
              # the smart target does not match, which would reattach the filter to
              # the wrong sink. Together they make it wait, unlinked and
              # undestroyed, until its target reappears.
              "node.dont-fallback" = true;
              "node.linger" = true;
            };
          };
        }
      ];
    };

  equalizers = {
    # The XM5 sink keeps the same node.name in both card profiles, but
    # `headset-head-unit` is mono 8 kHz CVSD. Matching on api.bluez5.profile as
    # well keeps this stereo music EQ out of the call path.
    xm5 = mkEqualizer {
      id = "xm5";
      description = "Sony WH-1000XM5 Equalizer";
      preampMult = 0.326212;
      smartTarget = {
        "node.name" = "bluez_output.80_99_E7_98_24_D7.1";
        "api.bluez5.profile" = "a2dp-sink";
      };
      bands = [
        {
          type = "bq_lowshelf";
          freq = 105.0;
          gain = -4.4;
          q = 0.7;
        }
        {
          type = "bq_peaking";
          freq = 62.3;
          gain = 1.8;
          q = 1.52;
        }
        {
          type = "bq_peaking";
          freq = 122.7;
          gain = -1.4;
          q = 2.12;
        }
        {
          type = "bq_peaking";
          freq = 190.8;
          gain = -4.6;
          q = 0.88;
        }
        {
          type = "bq_peaking";
          freq = 1109.3;
          gain = 4.5;
          q = 1.03;
        }
        {
          type = "bq_peaking";
          freq = 3116.5;
          gain = -2.4;
          q = 4.71;
        }
        {
          type = "bq_peaking";
          freq = 4482.8;
          gain = 4.0;
          q = 3.05;
        }
        {
          type = "bq_peaking";
          freq = 6295.7;
          gain = -3.9;
          q = 5.01;
        }
        {
          type = "bq_peaking";
          freq = 8951.4;
          gain = 2.5;
          q = 5.64;
        }
        {
          type = "bq_highshelf";
          freq = 10000.0;
          gain = 9.7;
          q = 0.7;
        }
      ];
    };

    # FiiO FD11 over the FiiO KA13 USB DAC — the everyday wired setup. A plain
    # USB sink, so node.name alone identifies it.
    fd11 = mkEqualizer {
      id = "fd11";
      description = "FiiO FD11 Equalizer";
      preampMult = 0.597723;
      smartTarget = {
        "node.name" = "alsa_output.usb-FIIO_FIIO_KA13-01.analog-stereo";
      };
      bands = [
        {
          type = "bq_lowshelf";
          freq = 105.0;
          gain = -2.0;
          q = 0.7;
        }
        {
          type = "bq_peaking";
          freq = 115.1;
          gain = -0.6;
          q = 2.25;
        }
        {
          type = "bq_peaking";
          freq = 180.5;
          gain = -3.9;
          q = 0.77;
        }
        {
          type = "bq_peaking";
          freq = 766.4;
          gain = 2.8;
          q = 1.06;
        }
        {
          type = "bq_peaking";
          freq = 2034.5;
          gain = -1.8;
          q = 1.35;
        }
        {
          type = "bq_peaking";
          freq = 2813.7;
          gain = 1.3;
          q = 3.55;
        }
        {
          type = "bq_peaking";
          freq = 3431.6;
          gain = 3.9;
          q = 2.33;
        }
        {
          type = "bq_peaking";
          freq = 5107.8;
          gain = -3.0;
          q = 5.24;
        }
        {
          type = "bq_peaking";
          freq = 9148.5;
          gain = 4.2;
          q = 0.87;
        }
        {
          type = "bq_highshelf";
          freq = 10000.0;
          gain = -2.7;
          q = 0.7;
        }
      ];
    };
  };
in
{
  xdg.configFile = lib.mapAttrs' (
    id: cfg:
    lib.nameValuePair "pipewire/pipewire.conf.d/50-${id}-equalizer.conf" {
      text = builtins.toJSON cfg;
    }
  ) equalizers;
}
