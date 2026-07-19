#!/usr/bin/env bash

set -euo pipefail

root_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
stamp=$(date +%Y%m%d-%H%M%S)
backup_dir="$HOME/Backups/camellia-niri-setup/$stamp"
dry_run=${DRY_RUN:-0}
replace_configs=${REPLACE_CONFIGS:-0}

run() {
    printf '+ '
    printf '%q ' "$@"
    printf '\n'
    (( dry_run )) || "$@"
}

backup_path() {
    local path=$1 rel
    [[ -e "$path" || -L "$path" ]] || return 0
    rel=${path#"$HOME"/}
    run mkdir -p "$backup_dir/$(dirname -- "$rel")"
    run cp -a "$path" "$backup_dir/$rel"
}

run mkdir -p "$HOME/.config" "$HOME/.local/share" "$HOME/Pictures/Wallpapers"

while IFS= read -r -d '' source; do
    name=$(basename -- "$source")
    backup_path "$HOME/.config/$name"
    if (( replace_configs )); then
        run rm -rf "$HOME/.config/$name"
        run cp -a "$source" "$HOME/.config/$name"
    else
        run mkdir -p "$HOME/.config/$name"
        run cp -a "$source/." "$HOME/.config/$name/"
    fi
done < <(find "$root_dir/dotfiles/.config" -mindepth 1 -maxdepth 1 -print0)

if (( dry_run )); then
    printf '+ replace @HOME@ placeholders and generate GTK bookmarks\n'
else
    sed -i "s|@HOME@|$HOME|g" "$HOME/.config/swaylock/config"
    {
        printf 'file://%s/Documents\n' "$HOME"
        printf 'file://%s/Music\n' "$HOME"
        printf 'file://%s/Pictures\n' "$HOME"
        printf 'file://%s/Videos\n' "$HOME"
        printf 'file://%s/Downloads\n' "$HOME"
    } > "$HOME/.config/gtk-3.0/bookmarks"
fi

backup_path "$HOME/.config/systemd/user"
run mkdir -p "$HOME/.config/systemd/user"
run cp -a "$root_dir/system/systemd-user/." "$HOME/.config/systemd/user/"

# Recreate dynamic-color links for the target user's home directory.
run ln -sfn "$HOME/.cache/wal/colors-swaync.css" "$HOME/.config/swaync/colors.css"
run ln -sfn "$HOME/.cache/wal/colors-rofi-dark.rasi" "$HOME/.config/rofi/themes/rofi-colors.rasi"
run ln -sfn "$HOME/.cache/wal/colors-kitty.conf" "$HOME/.config/kitty/colors-kitty.conf"
run ln -sfn "$HOME/.cache/wal/colors-waybar.css" "$HOME/.config/wlogout/colors.css"
run ln -sfn "$HOME/.cache/wal/colors-waybar.css" "$HOME/.config/waybar/theme.css"

# GTK 4 follows the packaged Layan theme without copying generated theme files.
if [[ -d /usr/share/themes/Layan-Dark/gtk-4.0 ]]; then
    run ln -sfn /usr/share/themes/Layan-Dark/gtk-4.0/gtk.css "$HOME/.config/gtk-4.0/gtk.css"
    run ln -sfn /usr/share/themes/Layan-Dark/gtk-4.0/gtk-dark.css "$HOME/.config/gtk-4.0/gtk-dark.css"
    run ln -sfn /usr/share/themes/Layan-Dark/gtk-4.0/assets "$HOME/.config/gtk-4.0/assets"
fi

if [[ ! -d "$HOME/Pictures/Wallpapers" ]] || ! find "$HOME/Pictures/Wallpapers" -maxdepth 1 -type f -print -quit | grep -q .; then
    run cp -a "$root_dir/assets/wallpapers/default.png" "$HOME/Pictures/Wallpapers/default.png"
fi

run chmod +x "$HOME/.config/niri/scripts/"*.sh
run systemctl --user daemon-reload

# Bind Niri-only services to niri.service, as recommended by the upstream
# systemd integration. Do not start them in the currently running Plasma or
# other desktop session.
wants_dir="$HOME/.config/systemd/user/niri.service.wants"
run mkdir -p "$wants_dir"

for unit in swayidle.service niri-power-effects.service niri-power-effects.path; do
    run ln -sfn "../$unit" "$wants_dir/$unit"
done

# Remove links created by older releases that started these services for every
# user session, including Plasma and text logins.
for unit in niri-power-effects.service niri-power-effects.path niri-low-battery.service; do
    run rm -f "$HOME/.config/systemd/user/default.target.wants/$unit"
done

battery_detected=0
for type_file in /sys/class/power_supply/*/type; do
    [[ -r "$type_file" ]] || continue
    if grep -qx Battery "$type_file"; then
        battery_detected=1
        break
    fi
done

if (( battery_detected )); then
    run ln -sfn ../niri-low-battery.service "$wants_dir/niri-low-battery.service"
else
    run rm -f "$wants_dir/niri-low-battery.service"
    printf '+ skip low-battery service: no battery detected\n'
fi

if command -v gsettings >/dev/null; then
    run gsettings set org.gnome.desktop.interface gtk-theme Layan-Dark
    run gsettings set org.gnome.desktop.interface icon-theme Papirus-Dark
    run gsettings set org.gnome.desktop.interface cursor-theme Bibata-Modern-Ice
    run gsettings set org.gnome.desktop.interface color-scheme prefer-dark
fi

printf '\nUser configuration deployed. Backup: %s\n' "$backup_dir"
printf 'Log out and back in after the system setup finishes.\n'
