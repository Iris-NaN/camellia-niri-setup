#!/usr/bin/env bash

set -u

destination="$HOME/Backups/dotfiles"
timestamp=$(date +%Y%m%d-%H%M%S)
archive="$destination/dotfiles-$timestamp.tar.gz"

mkdir -p "$destination"

items=(
    ".config/niri"
    ".config/waybar"
    ".config/kitty"
    ".config/swaylock"
    ".config/swayidle"
    ".config/btop"
    ".config/zed"
    ".config/nvim"
    ".config/systemd/user"
    ".config/Code/User/settings.json"
    ".config/Code/User/keybindings.json"
)

existing=()
for item in "${items[@]}"; do
    [[ -e "$HOME/$item" ]] && existing+=("$item")
done

tar -C "$HOME" \
    --exclude='.config/niri/backups' \
    --exclude='.config/niri/.cache' \
    --exclude='.config/niri/.git' \
    --exclude='Cache' \
    --exclude='GPUCache' \
    -czf "$archive" "${existing[@]}"

printf '%s\n' "$archive"
