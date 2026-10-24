#!/bin/bash

case "${1:-}" in
    --lock)
        exec "$HOME/.config/niri/scripts/lock-screen.sh"
        ;;
    --poweroff)
        "$HOME/.config/niri/scripts/uptime.sh"
        "$HOME/.config/niri/scripts/notification.sh" logout
        systemctl poweroff --now
        ;;
    --reboot)
        "$HOME/.config/niri/scripts/uptime.sh"
        "$HOME/.config/niri/scripts/notification.sh" logout
        systemctl reboot --now
        ;;
    --logout)
        "$HOME/.config/niri/scripts/uptime.sh"
        "$HOME/.config/niri/scripts/notification.sh" logout
        niri msg action quit --skip-confirmation
        ;;
    --suspend)
        "$HOME/.config/niri/scripts/uptime.sh"
        "$HOME/.config/niri/scripts/notification.sh" logout
        systemctl suspend --now
        ;;
    *)
        printf 'Usage: %s {--lock|--logout|--suspend|--reboot|--poweroff}\n' "$0" >&2
        exit 64
        ;;
esac
