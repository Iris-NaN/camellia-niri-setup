#!/usr/bin/env bash

set -u

CARD=${BLUETOOTH_CARD:-$(pactl list cards short 2>/dev/null |
    awk '$2 ~ /^bluez_card\./ { print $2; exit }')}

if [[ -z "$CARD" ]]; then
  notify-send -u normal "Bluetooth" "No Bluetooth audio card found"
  exit 1
fi

PROFILE=$(pactl list cards 2>/dev/null |
  awk -v card="$CARD" 'index($0, "Name: " card) { found = 1 }
       found && /Active Profile:/ { print $3; exit }')

if [[ -z "$PROFILE" ]]; then
  notify-send -u normal "Bluetooth" "Failed to read the Bluetooth audio profile"
  exit 1
fi

if [[ "$PROFILE" == a2dp-sink* ]]; then
  if ! pactl set-card-profile "$CARD" headset-head-unit; then
    notify-send -u critical "Bluetooth" "Failed to enable the headset profile"
    exit 1
  fi
  # 等 pipewire 重排
  sleep 0.8
  # 把 bt mic 提为默认
  BT_SRC=$(wpctl status 2>/dev/null | grep -oP 'bluez_input\.\S+' | head -1)
  [[ -n "$BT_SRC" ]] && wpctl set-default "$BT_SRC"
  notify-send -t 2000 -i audio-headset "Bluetooth" "🎤 Mic ON  (HFP · 音质降级)"
else
  if ! pactl set-card-profile "$CARD" a2dp-sink; then
    notify-send -u critical "Bluetooth" "Failed to enable the A2DP profile"
    exit 1
  fi
  notify-send -t 2000 -i audio-speakers "Bluetooth" "🎵 Hi-Fi ON  (A2DP)"
fi
