#!/usr/bin/env bash

# Lock the session and turn the screen off. Used by the "Mod+L" bind and by the
# swayidle "lock"/"before-sleep" events: swaylock takes over the session first,
# and only then are the monitors powered off, so the desktop is never exposed.
# niri powers the monitors back on when it receives input or when the session is
# unlocked.

set -u

swaylock -f || exit 1

niri msg action power-off-monitors
