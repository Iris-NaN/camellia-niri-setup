#!/usr/bin/env bash

set -u

current=$(xdg-settings get default-web-browser 2>/dev/null || true)

desktop_exists() {
    [[ -f "$HOME/.local/share/applications/$1" || -f "/usr/share/applications/$1" ]]
}

if [[ -n "$current" ]] && desktop_exists "$current"; then
    exit 0
fi

if command -v firefox-developer-edition >/dev/null; then
    fallback="firefox-developer-edition.desktop"
elif command -v microsoft-edge-stable >/dev/null; then
    fallback="com.microsoft.Edge.desktop"
else
    notify-send -u normal "Default browser" "No supported browser was found"
    exit 1
fi

xdg-settings set default-web-browser "$fallback"
xdg-mime default "$fallback" x-scheme-handler/http
xdg-mime default "$fallback" x-scheme-handler/https
notify-send -u low "Default browser" "Set to ${fallback%.desktop}"
