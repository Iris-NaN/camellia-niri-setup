#!/bin/bash

scripts_dir="$HOME/.config/niri/scripts"
wallpaper="$HOME/.config/niri/.cache/current_wallpaper.png"

if [[ -f "$wallpaper" ]]; then
    "$scripts_dir/set-wallpaper.sh" "$wallpaper"
else
    "$scripts_dir/Wallpaper.sh"
fi

"$scripts_dir/default_browser.sh"
