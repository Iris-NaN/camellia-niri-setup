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
run sudo pacman -S --needed "${official[@]}"

mapfile -t aur < <(read_packages "$root_dir/packages/aur.txt")
aur_helper=$(command -v yay || command -v paru || true)
if [[ -n "$aur_helper" ]]; then
    run "$aur_helper" -S --needed "${aur[@]}"
else
    printf '\nAUR helper not found. Install these packages manually, then rerun:\n'
    printf '  %s\n' "${aur[@]}"
    exit 2
fi
