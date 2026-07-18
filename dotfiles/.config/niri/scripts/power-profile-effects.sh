#!/usr/bin/env bash

set -u

normal_config="$HOME/.config/niri/config.kdl"
saver_config="$HOME/.config/niri/config-power-saver.kdl"
state_file="${XDG_RUNTIME_DIR:-/tmp}/niri-power-effects.state"

generate_saver_config() {
    local temporary
    temporary=$(mktemp "${saver_config}.XXXXXX") || return 1

    awk '
        function count(text, character, copy) {
            copy = text
            return gsub(character, "", copy)
        }

        /^blur[[:space:]]*\{/ {
            print "blur {"
            print "    off"
            print "}"
            depth = count($0, "[{]") - count($0, "[}]")
            skipping_blur = 1
            next
        }

        skipping_blur {
            depth += count($0, "[{]") - count($0, "[}]")
            if (depth <= 0)
                skipping_blur = 0
            next
        }

        /^[[:space:]]*animations[[:space:]]*\{/ {
            print "animations {"
            print "    off"
            print "}"
            depth = count($0, "[{]") - count($0, "[}]")
            skipping_animations = 1
            next
        }

        skipping_animations {
            depth += count($0, "[{]") - count($0, "[}]")
            if (depth <= 0)
                skipping_animations = 0
            next
        }

        {
            gsub(/blur true/, "blur false")
            gsub(/opacity 0\.92/, "opacity 1.0")
            if ($0 ~ /^[[:space:]]*on[[:space:]]*$/)
                sub(/on/, "off")
            print
        }
    ' "$normal_config" > "$temporary"

    if ! niri validate -c "$temporary" >/dev/null 2>&1; then
        rm -f "$temporary"
        notify-send -u critical "Niri power effects" "Generated power-saver config is invalid"
        return 1
    fi

    mv -f "$temporary" "$saver_config"
}

apply_profile() {
    local profile=$1

    if [[ "$profile" == "power-saver" ]]; then
        generate_saver_config || return 1
        niri msg action load-config-file --path "$saver_config" >/dev/null
        notify-send -u low "Power saver" "Blur, shadows and animations disabled"
    else
        niri msg action load-config-file --path "$normal_config" >/dev/null
        notify-send -u low "Power profile" "Visual effects restored"
    fi
}

current_profile() {
    powerprofilesctl get 2>/dev/null
}

sync_profile() {
    local profile
    profile=$(current_profile) || return 1

    if [[ "$profile" != "${last_profile:-}" ]]; then
        apply_profile "$profile" || return 1
        last_profile=$profile
        printf '%s\n' "$profile" > "$state_file"
    fi
}

case "${1:-watch}" in
    --generate-only)
        generate_saver_config
        exit
        ;;
    --once)
        last_profile=""
        sync_profile
        exit
        ;;
esac

last_profile=""
sync_profile || exit 1

# React only when power-profiles-daemon emits an ActiveProfile change.
gdbus monitor \
    --system \
    --dest net.hadess.PowerProfiles \
    --object-path /net/hadess/PowerProfiles |
while IFS= read -r event; do
    if [[ "$event" == *"ActiveProfile"* ]]; then
        sleep 1
        sync_profile
    fi
done

# Restart the systemd service if the D-Bus monitor unexpectedly exits.
exit 1
