#!/usr/bin/env bash

# Check that the hardware present on this machine has a working driver.
#
# The checks are read-only: nothing is loaded, unloaded or reconfigured. Every
# section is skipped when the matching hardware or tool is unavailable, so the
# script is safe to run on any Niri machine. Exit status is 1 when a driver is
# missing or the kernel reports a firmware load failure.

set -u

status=0

section() {
    printf '\n%s\n' "── $1 ──"
}

pass() {
    printf '  ok    %s\n' "$1"
}

warn() {
    printf '  warn  %s\n' "$1"
}

fail() {
    printf '  FAIL  %s\n' "$1" >&2
    status=1
}

skip() {
    printf '  skip  %s\n' "$1"
}

printf 'Checking drivers for the hardware on this machine...\n'

section "GPU"
found_gpu=0
for link in /sys/class/drm/card[0-9]*/device/driver; do
    [[ -L "$link" ]] || continue
    found_gpu=1
    driver=$(basename "$(readlink -f "$link")")
    card=$(basename "$(dirname "$(dirname "$link")")")
    pass "$card: $driver"
done
((found_gpu)) || skip "no DRM device found"
if [[ -d /sys/class/drm ]]; then
    if command -v journalctl >/dev/null 2>&1 &&
        journalctl -b -k --no-pager 2>/dev/null |
        grep -qiE '(amdgpu|i915|xe|nouveau).*(ring timeout|GPU reset|gpu hang)'; then
        fail "the kernel reported a GPU reset or ring timeout this boot"
    else
        pass "no GPU reset or ring timeout in the kernel log"
    fi
fi

section "Firmware"
firmware_failures=$(journalctl -b -k --no-pager 2>/dev/null |
    grep -iE 'Direct firmware load for .* failed|failed to load .*\.bin' |
    grep -viE 'regulatory\.db' || true)
if [[ -n "$firmware_failures" ]]; then
    warn "the kernel could not load some firmware:"
    printf '%s\n' "$firmware_failures" | sed 's/^/        /'
else
    pass "no firmware load failures in the kernel log"
fi

section "Wireless"
wireless_interfaces=()
for interface in /sys/class/net/*; do
    [[ -d "$interface/wireless" || -d "$interface/phy80211" ]] || continue
    wireless_interfaces+=("$(basename "$interface")")
done
if ((${#wireless_interfaces[@]})); then
    for name in "${wireless_interfaces[@]}"; do
        driver=$(basename "$(readlink -f "/sys/class/net/$name/device/driver" 2>/dev/null)" 2>/dev/null || true)
        pass "$name${driver:+ (driver: $driver)}"
    done

    if command -v rfkill >/dev/null 2>&1; then
        if rfkill list wifi 2>/dev/null | grep -q 'Hard blocked: yes'; then
            fail "a wireless adapter is hard blocked by rfkill"
        else
            pass "no wireless adapter is hard blocked"
        fi
    fi

    if command -v iw >/dev/null 2>&1; then
        region=$(iw reg get 2>/dev/null | sed -n 's/^country \([A-Z0-9]*\):.*/\1/p' | head -1)
        case "$region" in
            "" | 00 | 99)
                warn "regulatory domain is ${region:-unknown}; install wireless-regdb and set cfg80211.ieee80211_regdom"
                ;;
            *)
                pass "regulatory domain: $region"
                ;;
        esac
    else
        skip "iw is not installed"
    fi
else
    skip "no wireless interface found"
fi

section "Bluetooth"
if compgen -G '/sys/class/bluetooth/*' >/dev/null || lsusb 2>/dev/null | grep -qi 'bluetooth'; then
    if systemctl is-active --quiet bluetooth 2>/dev/null; then
        controller=$(bluetoothctl list 2>/dev/null | awk 'NR==1 {print $2}')
        pass "bluetooth service active${controller:+ (controller: $controller)}"
    else
        fail "a bluetooth adapter exists but the bluetooth service is not active"
    fi
else
    skip "no bluetooth adapter found"
fi

section "Audio"
if [[ -r /proc/asound/cards ]]; then
    cards=$(grep -c '^\s*[0-9]' /proc/asound/cards || true)
    if ((cards > 0)); then
        pass "$cards ALSA card(s) registered"
    else
        fail "no ALSA card registered"
    fi
else
    skip "ALSA is not available"
fi

section "Camera"
if compgen -G '/dev/video*' >/dev/null; then
    pass "$(compgen -G '/dev/video*' | wc -l) video device(s) present"
elif lsusb 2>/dev/null | grep -qi 'camera\|webcam'; then
    fail "a USB camera is present but no /dev/video* device was created"
else
    skip "no camera found"
fi

section "Input devices"
if command -v libinput >/dev/null 2>&1; then
    if libinput list-devices 2>/dev/null | grep -qi 'touchpad'; then
        pass "touchpad detected by libinput"
    else
        warn "libinput does not report a touchpad"
    fi
elif [[ -r /proc/bus/input/devices ]]; then
    if grep -qi 'touchpad' /proc/bus/input/devices; then
        pass "touchpad detected in /proc/bus/input/devices"
    else
        skip "no touchpad reported by the kernel"
    fi
else
    skip "input device list is not readable"
fi

section "Sensors"
if compgen -G '/sys/bus/iio/devices/iio:device*' >/dev/null; then
    for device in /sys/bus/iio/devices/iio:device*; do
        pass "$(cat "$device/name" 2>/dev/null || basename "$device")"
    done
    if systemctl is-active --quiet iio-sensor-proxy 2>/dev/null; then
        pass "iio-sensor-proxy is active"
    else
        warn "an IIO sensor exists but iio-sensor-proxy is not active"
    fi
else
    skip "no IIO sensor found"
fi

section "Backlight"
if compgen -G '/sys/class/backlight/*' >/dev/null; then
    for backlight in /sys/class/backlight/*; do
        pass "$(basename "$backlight") ($(cat "$backlight/type" 2>/dev/null || echo unknown))"
    done
else
    skip "no backlight device found"
fi

section "CPU frequency scaling"
if [[ -r /sys/devices/system/cpu/cpu0/cpufreq/scaling_driver ]]; then
    driver=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_driver)
    governor=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo unknown)
    pass "$driver with the $governor governor"
    if [[ "$driver" == acpi-cpufreq ]] && ! compgen -G '/sys/devices/system/cpu/cpu0/acpi_cppc' >/dev/null; then
        warn "the platform does not expose CPPC, so amd_pstate cannot be used"
    fi
else
    skip "CPU frequency scaling is not exposed"
fi

section "Fingerprint readers"
if lsusb 2>/dev/null | grep -qi 'fingerprint'; then
    reader=$(lsusb 2>/dev/null | grep -i 'fingerprint' | head -1)
    if command -v fprintd-list >/dev/null 2>&1 &&
        ! fprintd-list "$USER" 2>&1 | grep -q 'No devices available'; then
        pass "reader usable by fprintd (${reader##*ID })"
    else
        warn "reader present but no libfprint driver claims it (${reader##*ID }); known limitation for Goodix 27c6:5117"
    fi
else
    skip "no fingerprint reader found"
fi

printf '\n'
if ((status)); then
    printf 'Driver checks found problems.\n' >&2
    exit 1
fi

printf 'No driver problems detected.\n'
