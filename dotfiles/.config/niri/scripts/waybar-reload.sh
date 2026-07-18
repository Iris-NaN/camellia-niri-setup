#!/usr/bin/env bash

case "${1:-}" in
    --reload)
        if pgrep -x waybar >/dev/null; then
            pkill -SIGUSR2 -x waybar
        else
            setsid -f waybar >/dev/null 2>&1
        fi
        ;;
    --toggle)
        if pgrep -x waybar >/dev/null; then
            pkill -SIGUSR1 -x waybar
        else
            setsid -f waybar >/dev/null 2>&1
        fi
        ;;
esac
