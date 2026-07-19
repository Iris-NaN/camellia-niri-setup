#!/usr/bin/env bash

set -u

icon_dir="$HOME/.config/niri/icons/brightness"
notification_timeout=1000
ddc_args=(--sleep-multiplier=0)
if [[ -n ${DDCUTIL_DISPLAY:-} ]]; then
    ddc_args+=(--display "$DDCUTIL_DISPLAY")
fi

notify_user() {
    local current=$1 bucket icon
    bucket=$(( (current + 5) / 10 * 10 ))
    (( bucket > 100 )) && bucket=100
    (( bucket < 0 )) && bucket=0
    icon="$icon_dir/brightness-${bucket}.png"
    notify-send -e -t "$notification_timeout" \
        -h string:x-canonical-private-synchronous:brightness_notif \
        -u low -i "$icon" "Brightness: ${current}%"
}

if compgen -G '/sys/class/backlight/*' >/dev/null; then
    get_brightness() {
        brightnessctl -m | awk -F, 'NR == 1 { gsub(/%/, "", $4); print $4 }'
    }

    change_brightness() {
        brightnessctl set "$1" -n >/dev/null
        local current
        current=$(get_brightness)
        [[ "$current" =~ ^[0-9]+$ ]] && notify_user "$current"
    }

    case ${1:---get} in
        --get) get_brightness ;;
        up) change_brightness '+10%' ;;
        down) change_brightness '10%-' ;;
        *) printf 'Usage: %s {--get|up|down}\n' "$0" >&2; exit 64 ;;
    esac
else
    if ! command -v ddcutil >/dev/null; then
        notify-send -u critical "Brightness" "ddcutil is required for external monitors"
        exit 1
    fi

    get_brightness() {
        ddcutil "${ddc_args[@]}" getvcp 10 2>/dev/null |
            sed -nE 's/.*current value = *([0-9]+).*/\1/p' |
            head -n 1
    }

    change_brightness() {
        local delta=$1 current new
        current=$(get_brightness)
        [[ "$current" =~ ^[0-9]+$ ]] || current=50
        new=$(( current + delta ))
        (( new > 100 )) && new=100
        (( new < 0 )) && new=0
        ddcutil "${ddc_args[@]}" setvcp 10 "$new" >/dev/null
        notify_user "$new"
    }

    case ${1:---get} in
        --get) get_brightness ;;
        up) change_brightness 10 ;;
        down) change_brightness -10 ;;
        *) printf 'Usage: %s {--get|up|down}\n' "$0" >&2; exit 64 ;;
    esac
fi
