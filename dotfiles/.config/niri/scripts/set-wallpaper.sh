#!/usr/bin/env bash

wallpaper=${1:-}
scripts_dir="$HOME/.config/niri/scripts"
cache_dir="$HOME/.config/niri/.cache"

if [[ -z "$wallpaper" || ! -f "$wallpaper" ]]; then
    notify-send -u critical "Wallpaper" "Image not found: $wallpaper"
    exit 1
fi

wallpaper=$(realpath "$wallpaper")
mkdir -p "$cache_dir"

# Stop the previous static wallpaper backend.
pkill -x swaybg 2>/dev/null || true

case "${wallpaper,,}" in
    *.jpg|*.jpeg|*.png)
        setsid -f swaybg -i "$wallpaper" -m fill >/dev/null 2>&1
        ;;
    *)
        notify-send -u critical "Wallpaper" "Unsupported format (use JPG/JPEG/PNG): $wallpaper"
        exit 1
        ;;
esac

ln -sfn "$wallpaper" "$cache_dir/current_wallpaper.png"
basename=${wallpaper##*/}
printf '%s\n' "${basename%.*}" > "$cache_dir/.wallpaper"

"$scripts_dir/wallcache.sh"
"$scripts_dir/pywal.sh"
