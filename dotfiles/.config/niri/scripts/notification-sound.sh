#!/usr/bin/env bash

set -u

sound_file="/usr/share/sounds/freedesktop/stereo/message.oga"
fallback_file="${XDG_CONFIG_HOME:-$HOME/.config}/niri/sounds/update.wav"

if [[ ! -r "$sound_file" ]]; then
    sound_file=$fallback_file
fi

[[ -r "$sound_file" ]] || exit 0

if command -v paplay >/dev/null 2>&1; then
    paplay "$sound_file" >/dev/null 2>&1 &
elif command -v pw-play >/dev/null 2>&1; then
    pw-play "$sound_file" >/dev/null 2>&1 &
fi
