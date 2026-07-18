#!/usr/bin/env bash

wallpaper_dir="$HOME/Pictures/Wallpapers"
setter="$HOME/.config/niri/scripts/set-wallpaper.sh"

mapfile -d '' -t wallpapers < <(
    find "$wallpaper_dir" -type f \
        \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.gif' \) \
        -print0
)

if (( ${#wallpapers[@]} == 0 )); then
    notify-send -u critical "Wallpaper" "No images found in $wallpaper_dir"
    exit 1
fi

"$setter" "${wallpapers[RANDOM % ${#wallpapers[@]}]}"
