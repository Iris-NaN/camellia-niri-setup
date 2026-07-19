#!/usr/bin/env bash

set -u

low_threshold=${LOW_BATTERY_THRESHOLD:-30}
critical_threshold=${CRITICAL_BATTERY_THRESHOLD:-15}
recovery_threshold=${BATTERY_RECOVERY_THRESHOLD:-35}
state_dir=${XDG_RUNTIME_DIR:-/tmp}
profile_state="$state_dir/niri-low-battery-previous-profile"
critical_state="$state_dir/niri-low-battery-critical-notified"

battery=$(upower -e 2>/dev/null | awk '/battery_/ { print; exit }')
if [[ -z "$battery" ]]; then
    exit 0
fi

read_value() {
    upower -i "$battery" 2>/dev/null |
        awk -F: -v key="$1" '$1 ~ "^[[:space:]]*" key "$" { gsub(/^[[:space:]]+/, "", $2); print $2; exit }'
}

numeric_le() {
    awk -v value="$1" -v limit="$2" 'BEGIN { exit !(value <= limit) }'
}

numeric_gt() {
    awk -v value="$1" -v limit="$2" 'BEGIN { exit !(value > limit) }'
}

restore_profile() {
    local previous=balanced

    if [[ -s "$profile_state" ]]; then
        read -r previous < "$profile_state"
    fi
    case "$previous" in
        performance|balanced|power-saver) ;;
        *) previous=balanced ;;
    esac

    powerprofilesctl set "$previous" 2>/dev/null || true
    rm -f "$profile_state" "$critical_state"
    notify-send -u low "电源状态" "已恢复 ${previous} 模式"
}

evaluate() {
    local percentage state value previous

    percentage=$(read_value percentage)
    state=$(read_value state)
    value=${percentage%%%}
    [[ "$value" =~ ^[0-9]+([.][0-9]+)?$ ]] || return 0

    if [[ "$state" == "discharging" ]] && numeric_le "$value" "$low_threshold"; then
        if [[ ! -e "$profile_state" ]]; then
            previous=$(powerprofilesctl get 2>/dev/null || printf 'balanced')
            printf '%s\n' "$previous" > "$profile_state"
            powerprofilesctl set power-saver 2>/dev/null || true
            notify-send -u normal "低电量" "电量 ${percentage}，已自动进入省电模式"
        fi

        if numeric_le "$value" "$critical_threshold" && [[ ! -e "$critical_state" ]]; then
            : > "$critical_state"
            notify-send -u critical "电量不足" "剩余 ${percentage}，请尽快连接电源"
        fi
    elif [[ -e "$profile_state" ]] && { [[ "$state" != "discharging" ]] || numeric_gt "$value" "$recovery_threshold"; }; then
        restore_profile
    elif numeric_gt "$value" "$critical_threshold"; then
        rm -f "$critical_state"
    fi
}

evaluate
upower --monitor-detail 2>/dev/null | while IFS= read -r line; do
    if [[ "$line" == *"percentage:"* || "$line" == *"state:"* ]]; then
        evaluate
    fi
done
