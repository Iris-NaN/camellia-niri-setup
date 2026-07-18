#!/usr/bin/env bash

agent="/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1"

pgrep -f "$agent" >/dev/null && exit 0

if [[ -x "$agent" ]]; then
    exec "$agent"
fi

notify-send -u critical "Polkit" "Authentication agent is missing"
exit 1
