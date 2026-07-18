#!/bin/bash

data_file="$HOME/.config/niri/data/emoji.txt"
theme="$HOME/.config/rofi/themes/rofi-emoji.rasi"

choice=$(rofi -dmenu -i -config "$theme" < "$data_file") || exit 0
[[ -n "$choice" ]] && printf '%s' "${choice%% *}" | wl-copy

