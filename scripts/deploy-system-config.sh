#!/usr/bin/env bash

set -euo pipefail

root_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
stamp=$(date +%Y%m%d-%H%M%S)
backup_dir="$HOME/Backups/camellia-niri-setup/system-$stamp"
dry_run=${DRY_RUN:-0}

run() {
    printf '+ '
    printf '%q ' "$@"
    printf '\n'
    (( dry_run )) || "$@"
}

run mkdir -p "$backup_dir"
for path in /etc/sddm.conf.d/theme.conf /etc/sddm.conf.d/theme.conf.user /etc/sddm.conf.d/virtualkbd.conf /etc/locale.conf; do
    if [[ -f "$path" ]]; then
        run cp -a "$path" "$backup_dir/$(basename -- "$path")"
    fi
done

run sudo install -d -m 0755 /etc/sddm.conf.d /usr/share/sddm/themes/SilentSDDM
run sudo cp -a "$root_dir/assets/sddm/SilentSDDM/." /usr/share/sddm/themes/SilentSDDM/
run sudo install -m 0644 "$root_dir/system/sddm.conf.d/theme.conf" /etc/sddm.conf.d/theme.conf
run sudo install -m 0644 "$root_dir/system/sddm.conf.d/virtualkbd.conf" /etc/sddm.conf.d/virtualkbd.conf

# Generate both locales and prefer Chinese with an English fallback.
if ! grep -Eq '^zh_CN.UTF-8 UTF-8' /etc/locale.gen; then
    printf 'Enable zh_CN.UTF-8 in /etc/locale.gen before continuing.\n' >&2
    exit 3
fi
run sudo locale-gen
if (( dry_run )); then
    printf '+ install locale.conf with LANG=zh_CN.UTF-8 and LANGUAGE=zh_CN:en_US\n'
else
    tmp_locale=$(mktemp)
    printf 'LANG=zh_CN.UTF-8\nLANGUAGE=zh_CN:en_US\n' > "$tmp_locale"
    sudo install -m 0644 "$tmp_locale" /etc/locale.conf
    rm -f "$tmp_locale"
fi

run sudo systemctl enable NetworkManager.service sddm.service fstrim.timer paccache.timer
printf '\nSystem configuration deployed. Backup: %s\n' "$backup_dir"
