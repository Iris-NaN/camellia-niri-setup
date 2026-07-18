#!/usr/bin/env bash
CARD="bluez_card.41_42_FF_93_1E_03"
PROFILE=$(pactl list cards | awk '/Name: '"$CARD"'/{found=1} found && /Active Profile:/{print $3; exit}')

if [[ "$PROFILE" == "a2dp-sink" || "$PROFILE" == a2dp-sink* ]]; then
  pactl set-card-profile "$CARD" headset-head-unit
  # 等 pipewire 重排
  sleep 0.8
  # 把 bt mic 提为默认
  BT_SRC=$(wpctl status 2>/dev/null | grep -oP 'bluez_input\.\S+' | head -1)
  [[ -n "$BT_SRC" ]] && wpctl set-default "$BT_SRC"
  notify-send -t 2000 -i audio-headset "Bluetooth" "🎤 Mic ON  (HFP · 音质降级)"
else
  pactl set-card-profile "$CARD" a2dp-sink
  notify-send -t 2000 -i audio-speakers "Bluetooth" "🎵 Hi-Fi ON  (A2DP)"
fi
