#!/usr/bin/env bash

set -u

battery="/org/freedesktop/UPower/devices/battery_BAT1"
state_file="${XDG_RUNTIME_DIR:-/tmp}/niri-low-battery-forced"

read_value() {
    upower -i "$battery" | awk -F: -v key="$1" '$1 ~ "^[[:space:]]*" key "$" { gsub(/^[[:space:]]+/, "", $2); print $2; exit }'
}

evaluate() {
    local percentage state value
    percentage=$(read_value percentage)
    state=$(read_value state)
    value=${percentage%%%}

    [[ "$value" =~ ^[0-9]+([.][0-9]+)?$ ]] || return 0

    if [[ "$state" == "discharging" ]] && awk "BEGIN { exit !($value <= 30) }"; then
        if [[ ! -e "$state_file" ]]; then
            powerprofilesctl set power-saver
            : > "$state_file"
            notify-send -u normal "低电量" "电量 ${percentage}，已自动进入省电模式"
        fi

        if awk "BEGIN { exit !($value <= 15) }"; then
            notify-send -u critical "电量不足" "剩余 ${percentage}，请尽快连接电源"
        fi
    elif [[ -e "$state_file" && "$state" != "discharging" ]]; then
        powerprofilesctl set balanced
        rm -f "$state_file"
        notify-send -u low "已连接电源" "已恢复平衡模式"
    fi
}

evaluate
upower --monitor-detail | while IFS= read -r line; do
    [[ "$line" == *"battery_BAT1"* || "$line" == *"percentage:"* || "$line" == *"state:"* ]] && evaluate
done
