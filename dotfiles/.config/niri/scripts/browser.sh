#!/usr/bin/env bash

set -u

choose_default() {
    local choices=() choice

    command -v firefox-developer-edition >/dev/null && choices+=("firefox-developer-edition.desktop")
    command -v microsoft-edge-stable >/dev/null && choices+=("com.microsoft.Edge.desktop")

    (( ${#choices[@]} > 0 )) || {
        notify-send -u normal "Default browser" "No supported browser was found"
        return 1
    }

    choice=$(printf '%s\n' "${choices[@]}" | fuzzel --dmenu --prompt="默认浏览器 > ")
    [[ -n "$choice" ]] || return 0

    xdg-settings set default-web-browser "$choice"
    xdg-mime default "$choice" x-scheme-handler/http
    xdg-mime default "$choice" x-scheme-handler/https
    notify-send -u low "Default browser" "Set to ${choice%.desktop}"
}

case "${1:-op}" in
    ch) choose_default ;;
    op) xdg-open about:blank ;;
esac
