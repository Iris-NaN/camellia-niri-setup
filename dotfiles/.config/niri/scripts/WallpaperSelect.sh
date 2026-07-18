#!/usr/bin/env bash

wallpaper_dir="$HOME/Pictures/Wallpapers"
setter="$HOME/.config/niri/scripts/set-wallpaper.sh"
theme=${1:-thm1}
random_label="Random wallpaper"

mapfile -d '' -t wallpapers < <(
    find "$wallpaper_dir" -type f \
        \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.gif' \) \
        -print0 | sort -z
)

if (( ${#wallpapers[@]} == 0 )); then
    notify-send -u critical "Wallpaper" "No images found in $wallpaper_dir"
    exit 1
fi

menu() {
    local path label
    for path in "${wallpapers[@]}"; do
        label=${path#"$wallpaper_dir"/}
        if [[ ${path,,} == *.gif ]]; then
            printf '%s\n' "$label"
        else
            printf '%s\0icon\x1f%s\n' "$label" "$path"
        fi
    done
    printf '%s\n' "$random_label"
}

case "$theme" in
    thm2) config="$HOME/.config/rofi/themes/rofi-wall-2.rasi" ;;
    *)    config="$HOME/.config/rofi/themes/rofi-wall.rasi" ;;
esac

choice=$(menu | rofi -dmenu -i -config "$config")
[[ -z "$choice" ]] && exit 0

if [[ "$choice" == "$random_label" ]]; then
    "$setter" "${wallpapers[RANDOM % ${#wallpapers[@]}]}"
else
    "$setter" "$wallpaper_dir/$choice"
fi
