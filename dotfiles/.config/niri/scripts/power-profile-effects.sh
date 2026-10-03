#!/usr/bin/env bash

set -u

config_dir=${NIRI_CONFIG_DIR:-$HOME/.config/niri}
normal_config="$config_dir/config.kdl"
saver_config="$config_dir/config-power-saver.kdl"
state_file="${XDG_RUNTIME_DIR:-/tmp}/niri-power-effects.state"
resync_interval=30
last_notified=""

# systemd user services do not necessarily inherit NIRI_SOCKET from the niri
# session, so find the compositor socket ourselves before talking to niri.
resolve_niri_socket() {
    if [[ -S ${NIRI_SOCKET:-} ]]; then
        return 0
    fi

    local candidate
    for candidate in \
        "${XDG_RUNTIME_DIR:-/tmp}/niri.${WAYLAND_DISPLAY:-wayland-1}."*.sock \
        "${XDG_RUNTIME_DIR:-/tmp}/niri."*.sock; do
        if [[ -S "$candidate" ]]; then
            export NIRI_SOCKET=$candidate
            return 0
        fi
    done

    printf '%s\n' 'power-profile-effects: no niri socket found' >&2
    return 1
}

# The service and niri.service can be started at the same time; wait briefly for
# the compositor socket instead of writing a wrong state on startup.
wait_for_niri_socket() {
    local attempt
    for attempt in $(seq 1 30); do
        resolve_niri_socket && return 0
        sleep 1
    done
    return 1
}

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

        /^[[:space:]]*shadow[[:space:]]*\{/ {
            shadow_depth = count($0, "[{]") - count($0, "[}]")
            in_shadow = 1
            print
            next
        }

        in_shadow {
            if ($0 ~ /^[[:space:]]*on[[:space:]]*$/)
                sub(/on/, "off")
            shadow_depth += count($0, "[{]") - count($0, "[}]")
            print
            if (shadow_depth <= 0)
                in_shadow = 0
            next
        }

        {
            gsub(/blur true/, "blur false")
            gsub(/opacity 0\.92/, "opacity 1.0")
            print
        }
    ' "$normal_config" > "$temporary"

    if command -v niri >/dev/null && ! niri validate -c "$temporary" >/dev/null 2>&1; then
        rm -f "$temporary"
        notify-send -u critical "Niri power effects" "Generated power-saver config is invalid"
        return 1
    fi

    mv -f "$temporary" "$saver_config"
}

read_state() {
    applied_profile=""
    applied_config=""
    if [[ -r "$state_file" ]]; then
        {
            read -r applied_profile || true
            read -r applied_config || true
        } < "$state_file"
    fi
}

mark_applied() {
    applied_profile=$1
    applied_config=$2
    printf '%s\n%s\n' "$1" "$2" > "$state_file"
}

notify_applied() {
    local profile=$1
    [[ "$profile" == "$last_notified" ]] && return 0
    last_notified=$profile

    if [[ "$profile" == "power-saver" ]]; then
        notify-send -u low "Power saver" "Blur, shadows and animations disabled"
    else
        notify-send -u low "Power profile" "Visual effects restored"
    fi
}

apply_profile() {
    local profile=$1 config

    if [[ "$profile" == "power-saver" ]]; then
        config=$saver_config
        generate_saver_config || return 1
    else
        config=$normal_config
    fi

    resolve_niri_socket || return 1

    if ! niri msg action load-config-file --path "$config" >/dev/null; then
        printf 'power-profile-effects: failed to load %s\n' "$config" >&2
        return 1
    fi

    mark_applied "$profile" "$config"
    notify_applied "$profile"
    printf 'power-profile-effects: applied %s (%s)\n' "$profile" "$config"
}

current_profile() {
    powerprofilesctl get 2>/dev/null
}

# Bring niri in line with the live power profile. The state file records what we
# last applied, so a failed load (for example a systemd service that cannot find
# the niri socket) is retried instead of being remembered as success.
sync_profile() {
    local profile

    profile=$(current_profile) || return 1
    [[ -n "$profile" ]] || return 1

    read_state

    if [[ "$profile" == "power-saver" ]]; then
        if [[ "$applied_profile" == "$profile" && "$applied_config" == "$saver_config" ]]; then
            return 0
        fi
    elif [[ "$applied_profile" == "$profile" && "$applied_config" == "$normal_config" ]]; then
        return 0
    fi

    apply_profile "$profile" || return 1
}

resync_timer() {
    while sleep "$resync_interval"; do
        sync_profile
    done
}

case "${1:-watch}" in
    --generate-only)
        generate_saver_config
        exit
        ;;
    --once)
        sync_profile
        exit
        ;;
esac

wait_for_niri_socket || exit 1

sync_profile || exit 1

# React to power-profiles-daemon ActiveProfile changes; the periodic resync is a
# fallback so a missed or failed load cannot leave the wrong effects enabled.
resync_timer &
resync_pid=$!
trap 'kill "$resync_pid" 2>/dev/null || true' EXIT

gdbus monitor \
    --system \
    --dest net.hadess.PowerProfiles \
    --object-path /net/hadess/PowerProfiles 2>/dev/null |
while IFS= read -r event; do
    if [[ "$event" == *"ActiveProfile"* ]]; then
        sleep 1
        sync_profile
    fi
done

# Restart the systemd service if the D-Bus monitor unexpectedly exits.
exit 1
