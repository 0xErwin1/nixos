{ pkgs, ... }:
let
  # Switch the audio profile of the currently active Bluetooth audio card.
  # Profiles are presented with friendly names ("Music (A2DP, LDAC)" instead
  # of "a2dp-sink-ldac"); the underlying technical id is preserved for the
  # actual switch via pactl set-card-profile.
  btProfile = pkgs.writeShellApplication {
    name = "bt-profile";
    runtimeInputs = with pkgs; [
      pulseaudio
      wofi
      libnotify
      gnused
      gawk
    ];
    text = ''
      card=$(pactl list cards short | awk '/bluez/ {print $2; exit}')

      if [[ -z "$card" ]]; then
        notify-send "Bluetooth" "No Bluetooth audio device connected"
        exit 0
      fi

      current=$(pactl list cards | awk -v c="$card" '
        $0 ~ "Name: " c { in_card = 1 }
        in_card && /Active Profile:/ {
          sub(/^[[:space:]]*Active Profile:[[:space:]]*/, "")
          print
          exit
        }
      ')

      profiles=$(pactl list cards | awk -v c="$card" '
        $0 ~ "Name: " c { in_card = 1; next }
        in_card && /^[[:space:]]+Profiles:/ { in_p = 1; next }
        in_p && /^[[:space:]]+[a-z]/ {
          sub(/:.*$/, "")
          gsub(/^[[:space:]]+/, "")
          print
          next
        }
        in_p && /^[[:space:]]+[A-Z]/ { in_p = 0; in_card = 0 }
      ' | grep -v '^off$' || true)

      if [[ -z "$profiles" ]]; then
        notify-send "Bluetooth" "No profiles available"
        exit 1
      fi

      # Map technical profile id to a friendly label.
      friendly() {
        local id="$1"
        local kind codec
        case "$id" in
          a2dp-sink-*)
            codec="''${id#a2dp-sink-}"
            kind="Music (A2DP"
            ;;
          a2dp-sink)
            codec=""
            kind="Music (A2DP"
            ;;
          headset-head-unit-*)
            codec="''${id#headset-head-unit-}"
            kind="Call (HFP"
            ;;
          headset-head-unit)
            codec=""
            kind="Call (HFP"
            ;;
          *)
            printf '%s' "$id"
            return
            ;;
        esac
        if [[ -n "$codec" ]]; then
          # Uppercase codec for readability (sbc -> SBC, ldac -> LDAC).
          codec=$(printf '%s' "$codec" | tr '[:lower:]' '[:upper:]' | sed 's/_/ /g')
          printf '%s, %s)' "$kind" "$codec"
        else
          printf '%s)' "$kind"
        fi
      }

      labels=""
      while IFS= read -r p; do
        [[ -z "$p" ]] && continue
        label=$(friendly "$p")
        if [[ "$p" == "$current" ]]; then
          label="* $label"
        else
          label="  $label"
        fi
        labels+="$label	$p"$'\n'
      done <<< "$profiles"

      selected=$(printf '%s' "$labels" | cut -f1 | wofi --dmenu --prompt "BT profile")
      [[ -z "$selected" ]] && exit 0

      profile_id=$(printf '%s' "$labels" | awk -F'\t' -v sel="$selected" '$1 == sel {print $2; exit}')
      [[ -z "$profile_id" ]] && exit 1

      pactl set-card-profile "$card" "$profile_id"
      notify-send "Bluetooth" "Profile: $(friendly "$profile_id")"
    '';
  };

  # List known Bluetooth devices (paired + connected) and toggle
  # connect/disconnect on selection. Uses `bluetoothctl devices` (no filter)
  # for compatibility with older bluez versions where `devices Paired`
  # silently returns nothing.
  btDevice = pkgs.writeShellApplication {
    name = "bt-device";
    runtimeInputs = with pkgs; [
      bluez
      wofi
      libnotify
      gnused
      gawk
    ];
    text = ''
      mapfile -t devices < <(bluetoothctl devices | sed 's/^Device //')

      if [[ "''${#devices[@]}" -eq 0 ]]; then
        notify-send "Bluetooth" "No known devices. Pair one first via blueman."
        exit 0
      fi

      lines=""
      for entry in "''${devices[@]}"; do
        mac="''${entry%% *}"
        name="''${entry#* }"
        info=$(bluetoothctl info "$mac" 2>/dev/null || true)
        # Skip devices that are not paired (random nearby devices that
        # appeared during a scan and were never paired).
        grep -q "Paired: yes" <<< "$info" || continue
        if grep -q "Connected: yes" <<< "$info"; then
          marker="[*]"
        else
          marker="[ ]"
        fi
        lines+="$marker $name	$mac"$'\n'
      done

      if [[ -z "$lines" ]]; then
        notify-send "Bluetooth" "No paired devices"
        exit 0
      fi

      selected=$(printf '%s' "$lines" | cut -f1 | wofi --dmenu --prompt "Bluetooth devices")
      [[ -z "$selected" ]] && exit 0

      mac=$(printf '%s' "$lines" | awk -F'\t' -v sel="$selected" '$1 == sel {print $2; exit}')
      name="''${selected#* }"

      [[ -z "$mac" ]] && exit 1

      if bluetoothctl info "$mac" | grep -q "Connected: yes"; then
        if bluetoothctl disconnect "$mac" >/dev/null; then
          notify-send "Bluetooth" "Disconnected: $name"
        else
          notify-send "Bluetooth" "Failed to disconnect $name"
        fi
      else
        if bluetoothctl connect "$mac" >/dev/null; then
          notify-send "Bluetooth" "Connected: $name"
        else
          notify-send "Bluetooth" "Failed to connect $name"
        fi
      fi
    '';
  };

  # Top-level Bluetooth menu. Extensible: add more entries here as new
  # scripts are introduced (battery, codec info, etc).
  btMenu = pkgs.writeShellApplication {
    name = "bt-menu";
    runtimeInputs = [
      pkgs.wofi
      btProfile
      btDevice
    ];
    text = ''
      entry=$(printf '%s\n' \
        "Switch audio profile" \
        "Connect / disconnect device" \
        | wofi --dmenu --prompt "Bluetooth")

      case "$entry" in
        "Switch audio profile") exec bt-profile ;;
        "Connect / disconnect device") exec bt-device ;;
      esac
    '';
  };
in
{
  home.packages = [
    btProfile
    btDevice
    btMenu
  ];
}
