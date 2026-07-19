#!/usr/bin/env bash

set -euo pipefail

root_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
stamp=$(date +%Y%m%d-%H%M%S)
backup_dir="$HOME/Backups/camellia-niri-setup/system-$stamp"
dry_run=${DRY_RUN:-0}
install_sddm_theme=${INSTALL_SDDM_THEME:-1}
system_locale=${SYSTEM_LOCALE:-}

run() {
    printf '+ '
    printf '%q ' "$@"
    printf '\n'
    (( dry_run )) || "$@"
}

run mkdir -p "$backup_dir"

backup_paths=()
if (( install_sddm_theme )); then
    backup_paths+=(/etc/sddm.conf.d/theme.conf /etc/sddm.conf.d/theme.conf.user /etc/sddm.conf.d/virtualkbd.conf)
fi
if [[ -n "$system_locale" ]]; then
    backup_paths+=(/etc/locale.conf /etc/locale.gen)
fi

for path in "${backup_paths[@]}"; do
    if [[ -f "$path" ]]; then
        run cp -a "$path" "$backup_dir/$(basename -- "$path")"
    fi
done

if (( install_sddm_theme )); then
    if [[ -d /usr/share/sddm/themes/SilentSDDM ]]; then
        run cp -a /usr/share/sddm/themes/SilentSDDM "$backup_dir/SilentSDDM"
    fi
    run sudo install -d -m 0755 /etc/sddm.conf.d /usr/share/sddm/themes/SilentSDDM
    run sudo cp -a "$root_dir/assets/sddm/SilentSDDM/." /usr/share/sddm/themes/SilentSDDM/
    run sudo install -m 0644 "$root_dir/system/sddm.conf.d/theme.conf" /etc/sddm.conf.d/theme.conf
    run sudo install -m 0644 "$root_dir/system/sddm.conf.d/virtualkbd.conf" /etc/sddm.conf.d/virtualkbd.conf
else
    printf '+ preserve existing SDDM theme\n'
fi

# Locale is an explicit machine policy, not an implicit Niri dependency.
if [[ -n "$system_locale" ]]; then
    escaped_locale=${system_locale//./\\.}
    if ! grep -Eq "^${escaped_locale}[[:space:]]+UTF-8" /etc/locale.gen; then
        if grep -Eq "^#[[:space:]]*${escaped_locale}[[:space:]]+UTF-8" /etc/locale.gen; then
            run sudo sed -i -E "s|^#[[:space:]]*(${escaped_locale}[[:space:]]+UTF-8)|\\1|" /etc/locale.gen
        else
            printf 'Locale is not available in /etc/locale.gen: %s\n' "$system_locale" >&2
            exit 3
        fi
    fi
    run sudo locale-gen
    if (( dry_run )); then
        printf '+ install locale.conf with LANG=%s\n' "$system_locale"
    else
        tmp_locale=$(mktemp)
        printf 'LANG=%s\n' "$system_locale" > "$tmp_locale"
        sudo install -m 0644 "$tmp_locale" /etc/locale.conf
        rm -f "$tmp_locale"
    fi
else
    printf '+ preserve existing system locale\n'
fi

run sudo systemctl enable NetworkManager.service sddm.service fstrim.timer paccache.timer
printf '\nSystem configuration deployed. Backup: %s\n' "$backup_dir"
