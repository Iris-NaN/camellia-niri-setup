#!/usr/bin/env bash

set -u

pictures_dir=${XDG_PICTURES_DIR:-$HOME/Pictures}
sound_file="/usr/share/sounds/freedesktop/stereo/screen-capture.oga"
save_dir=${2:-$pictures_dir/Screenshots}
save_file=$(date +'screenshot_niri_%y%m%d_%H%M%S.png')
temp_screenshot=$(mktemp --suffix=.png)
trap 'rm -f "$temp_screenshot"' EXIT

mkdir -p "$save_dir"

choice=$(printf 'Fullscreen\nSelected Area\n' |
    rofi -dmenu -replace -config "$HOME/.config/rofi/themes/rofi-screenshots.rasi" \
        -i -no-show-icons -l 2 -width 30 -p) || exit 0

case $choice in
    Fullscreen)
        grim "$temp_screenshot" || exit 1
        ;;
    'Selected Area')
        geometry=$(slurp) || exit 0
        grim -g "$geometry" "$temp_screenshot" || exit 1
        ;;
    *) exit 0 ;;
esac

[[ -f "$sound_file" ]] && paplay "$sound_file" >/dev/null 2>&1 &
satty --filename "$temp_screenshot" \
    --output-filename "$save_dir/$save_file" \
    --early-exit
