#!/usr/bin/env bash

set -euo pipefail

root_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
niri_dir="$root_dir/dotfiles/.config/niri"
kanshi_config="$root_dir/dotfiles/.config/kanshi/config"
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

if [[ ! -f "$kanshi_config" ]]; then
    printf 'Missing Kanshi configuration: %s\n' "$kanshi_config" >&2
    status=1
elif command -v kanshi >/dev/null; then
    # Kanshi has no separate --check mode. It parses the config before
    # connecting to Wayland, so an intentionally invalid display lets us verify
    # the configuration without touching the real session.
    printf 'Validating Kanshi configuration...\n'
    mkdir -p "$temporary/kanshi-runtime"
    if ! (
        unset WAYLAND_SOCKET
        export XDG_RUNTIME_DIR="$temporary/kanshi-runtime"
        export WAYLAND_DISPLAY=invalid-wayland-display
        kanshi -c "$kanshi_config"
    ) >"$temporary/kanshi.log" 2>&1; then
        :
    fi
    if ! grep -Fq 'failed to connect to display' "$temporary/kanshi.log"; then
        cat "$temporary/kanshi.log" >&2
        printf 'Kanshi configuration failed to parse.\n' >&2
        status=1
    fi
else
    printf 'Skipping Kanshi validation: kanshi is not installed.\n'
fi

if command -v fuzzel >/dev/null; then
    printf 'Validating Fuzzel configuration...\n'
    LC_ALL=C.UTF-8 \
        fuzzel --config="$root_dir/dotfiles/.config/fuzzel/fuzzel.ini" --check-config
else
    printf 'Skipping Fuzzel validation: fuzzel is not installed.\n'
fi

if (( status )); then
    exit 1
fi

printf 'All available checks passed.\n'
