#!/usr/bin/env bash

set -euo pipefail

root_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
dry_run=${DRY_RUN:-0}

read_packages() {
    sed -E '/^[[:space:]]*(#|$)/d' "$1"
}

run() {
    printf '+ '
    printf '%q ' "$@"
    printf '\n'
    (( dry_run )) || "$@"
}

if [[ ! -f /etc/arch-release ]]; then
    printf 'This installer currently supports Arch Linux only.\n' >&2
    exit 1
fi

mapfile -t official < <(read_packages "$root_dir/packages/official.txt")
run sudo pacman -S --needed base-devel
run sudo pacman -S --needed "${official[@]}"

mapfile -t aur < <(read_packages "$root_dir/packages/aur.txt")
aur_helper=$(command -v yay || command -v paru || true)
if [[ -n "$aur_helper" ]]; then
    for package in "${aur[@]}"; do
        if ! run "$aur_helper" -S --needed "$package"; then
            printf '\nOptional AUR package failed: %s; continuing with the remaining packages.\n' "$package" >&2
        fi
    done
else
    printf '\nAUR helper not found; continuing without these optional packages:\n' >&2
    printf '  %s\n' "${aur[@]}" >&2
fi

if (( ! dry_run )); then
    missing_aur=()
    for package in "${aur[@]}"; do
        pacman -Qq "$package" >/dev/null 2>&1 || missing_aur+=("$package")
    done

    if ((${#missing_aur[@]})); then
        printf '\nThe desktop can start, but these optional AUR packages are still missing:\n' >&2
        printf '  %s\n' "${missing_aur[@]}" >&2
    fi
fi
