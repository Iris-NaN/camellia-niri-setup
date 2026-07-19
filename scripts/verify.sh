#!/usr/bin/env bash

set -euo pipefail

root_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
niri_dir="$root_dir/dotfiles/.config/niri"
status=0

printf 'Checking shell syntax...\n'
while IFS= read -r -d '' script; do
    if ! bash -n "$script"; then
        status=1
    fi
done < <(find "$root_dir" -type f -name '*.sh' -print0)

printf 'Checking referenced Niri helper scripts...\n'
while IFS= read -r reference; do
    script=${reference##*/}
    if [[ ! -f "$niri_dir/scripts/$script" ]]; then
        printf 'Missing helper script: %s\n' "$script" >&2
        status=1
    fi
done < <(
    grep -RhoE '(~|\$HOME)/\.config/niri/scripts/[A-Za-z0-9._-]+\.sh' \
        "$root_dir/dotfiles/.config/niri" \
        "$root_dir/dotfiles/.config/waybar" |
        sort -u
)

printf 'Regenerating the derived power-saver configuration...\n'
temporary=$(mktemp -d)
trap 'rm -rf "$temporary"' EXIT
mkdir -p "$temporary/niri/conf.d"
cp "$niri_dir/config.kdl" "$temporary/niri/config.kdl"
cp "$niri_dir/conf.d/binds.kdl" "$temporary/niri/conf.d/binds.kdl"
NIRI_CONFIG_DIR="$temporary/niri" \
    "$niri_dir/scripts/power-profile-effects.sh" --generate-only

if ! cmp -s "$temporary/niri/config-power-saver.kdl" "$niri_dir/config-power-saver.kdl"; then
    printf 'config-power-saver.kdl is stale; regenerate it from config.kdl.\n' >&2
    diff -u "$niri_dir/config-power-saver.kdl" "$temporary/niri/config-power-saver.kdl" || true
    status=1
fi

if command -v niri >/dev/null; then
    printf 'Validating Niri KDL files...\n'
    niri validate -c "$niri_dir/config.kdl"
    niri validate -c "$niri_dir/config-power-saver.kdl"
else
    printf 'Skipping KDL validation: niri is not installed.\n'
fi

if (( status )); then
    exit 1
fi

printf 'All available checks passed.\n'
