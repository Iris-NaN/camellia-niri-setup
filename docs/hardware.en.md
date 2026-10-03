# Local hardware notes

This document records the hardware of this machine, the drivers it uses, and a
few traps that only show up on real hardware. The goal is to avoid rediscovering
all of it after a reinstall, a kernel change or a new machine.

Re-check the current state at any time with the repository's read-only script:

```bash
./scripts/verify-drivers.sh
```

## Machine

| Item | Value |
| --- | --- |
| Vendor / model | HUAWEI HLY-WX9XX (MateBook D 14, board HLY-WX9XX-PCB) |
| CPU | AMD Ryzen 5 3550H with Radeon Vega Mobile Gfx |
| Memory | 14 GiB |
| Storage | SK hynix PC601 NVMe 512 GB (`nvme0n1`) |
| Kernel | linux-zen 7.2.8 |
| Boot | GRUB 2.14, EFI |

## Driver overview

| Device | Kernel driver | Firmware / notes |
| --- | --- | --- |
| GPU | `amdgpu` | PCI `1002:15d8` (Picasso / Raven 2), Mesa 26.2.3 + `vulkan-radeon`, picasso firmware complete |
| Wireless | `rtw88_8822ce` | Realtek RTL8822CE, `rtw88/rtw8822c_fw.bin`, firmware version 9.9.15 |
| Bluetooth | `btusb` + `btrtl` | USB `1358:c123`, loads `rtl_bt/rtl8822cu_fw.bin` |
| Audio | `snd_hda_intel` | Realtek ALC256, `alsa-ucm-conf` installed |
| Camera | `uvcvideo` | USB `13d3:56db` (ov9734 / AzureWave), UVC 1.50 |
| Touchpad | `elan_i2c` | `ELAN2204:00 04F3:30F5` (I²C) |
| Accelerometer | `lis2dh12` (SMO8840) | IIO `iio:device0`, orientation via `iio-sensor-proxy` |
| Backlight | `amdgpu_bl1` | requires `acpi_backlight=native` (see below) |
| CPU microcode | `amd-ucode` | `/boot/amd-ucode.img` |
| Fingerprint | none | Goodix `27c6:5117`, see "Known limitations" |

## Kernel command line

`GRUB_CMDLINE_LINUX_DEFAULT` in `/etc/default/grub`:

```
loglevel=3 rw usb-storage.quirks=346d:5678:u acpi_backlight=native cfg80211.ieee80211_regdom=CN
```

- `acpi_backlight=native` lets `amdgpu` provide the backlight interface directly.
  Without it `/sys/class/backlight` may end up empty and `brightnessctl` cannot
  change the brightness.
- `cfg80211.ieee80211_regdom=CN` sets the wireless regulatory domain early,
  **independently** of when `regulatory.db` is loaded.
- `usb-storage.quirks=346d:5678:u` works around a USB storage device.

## Wireless regulatory domain (important)

On a fresh install `iw reg get` reports `country 00: DFS-UNSET`, the most
conservative world domain: much of the 5 GHz band is unavailable and transmit
power is capped. The cause is a missing regulatory database:

```
kernel: faux_driver regulatory: Direct firmware load for regulatory.db failed with error -2
kernel: cfg80211: failed to load regulatory.db
```

The fix has two layers:

1. Install `wireless-regdb` (core repository), which provides
   `/usr/lib/firmware/regulatory.db` and `regulatory.db.p7s`.
2. Add `cfg80211.ieee80211_regdom=CN` to the kernel command line so the domain is
   correct even if the database fails to load.

Note that the early `Direct firmware load for regulatory.db failed` message is a
**timing artefact** (the root filesystem is not mounted yet at that point);
`cfg80211` reads the database fine when it is loaded later. To decide whether the
domain actually took effect, check that `iw reg get` reports `country CN` rather
than trusting the early log line.

> Hard-learned lesson: never repeatedly `modprobe -r cfg80211 / mac80211 /
> rtw88_8822ce` just to verify that file. The wireless adapter runs on those
> modules and unloading them drops the network immediately. Use `iw reg get` to
> check the state, and when a reload is truly needed, only `modprobe` (load),
> never `-r`.

## Known limitations

These are hardware or ecosystem limits, **not configuration mistakes**, and do
not need further investigation:

- **The fingerprint reader does not work.** Goodix `27c6:5117` has no usable
  open-source driver on Linux. The kernel only enumerates it as a generic USB
  device; `libfprint-tod-git` and every TOD driver lack this ID, so
  `fprintd-list` always answers `No devices available`. It is unusable unless an
  upstream driver appears.
- **`amd_pstate` is unavailable.** This Raven2 APU does not expose ACPP CPPC
  (`/sys/devices/system/cpu/cpu0/acpi_cppc` does not exist), so only
  `acpi-cpufreq` with `schedutil` is possible. The kernel is built with
  `CONFIG_X86_AMD_PSTATE`, but it is useless here; do not change kernel
  parameters hoping for it.
- **The firmware packages cannot be trimmed.** The `linux-firmware` metapackage
  **hard-depends** on every split package (intel / nvidia / broadcom / mediatek /
  atheros / ti / cirrus and friends), so the roughly 350 MiB this machine does
  not use cannot be removed safely.
- The `ccp 0000:03:00.2: psp: unable to access the device: you might be running a
  broken BIOS` and `amdgpu: psp gfx command LOAD_TA(0x1) failed` log lines are
  common, harmless Raven warnings.

## Past traps

- **`niri-power-effects.service` failed to start at boot.** The unit is pulled in
  by `default.target`, but it carried `Requisite=graphical-session.target`, and
  that target only becomes active once `niri.service` is up. The start was
  refused outright and the daemon stayed dead for the whole session. The fix is
  to drop the redundant `Requisite` from the session units while keeping `PartOf`
  and `After=`. See commit `f779bdc`.
- **The screen stayed on while locked.** The `swayidle` `lock` event used to run
  `swaylock` only. It now calls `lock-screen.sh`, which locks first and then runs
  `niri msg action power-off-monitors`. Niri powers the monitors back on when it
  receives input or when the session is unlocked, so no extra wiring is needed.
  See commit `bc1f19e`.

## How to re-check

```bash
./scripts/verify-drivers.sh     # hardware and driver check (read-only)
iw reg get | head -2            # expect country CN
nmcli device status | grep wlan # expect connected
```
