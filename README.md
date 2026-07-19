# Camellia Niri Setup

Reproduce this Arch Linux Niri desktop on another computer with a self-contained,
auditable installer. The project is inspired by `niriconf`, but avoids cached
state, destructive uninstall steps, and machine-specific output names.

## Included software

- Graphical core: Niri, Waybar, SwayNC, Fuzzel/Rofi, Kitty, portals and Polkit
- Login: SDDM with the bundled SilentSDDM theme
- Appearance: Layan Dark, Papirus Dark, Bibata cursor, Pywal dynamic colors
- Files: Thunar, GVfs, Tumbler and Ark
- Browser: Firefox Developer Edition with Simplified Chinese language pack
- Input: Fcitx5 with Chinese addons
- Basics: NetworkManager, PipeWire, Bluetooth, clipboard, brightness, media,
  screenshots, power profiles, monitoring and common CLI utilities

Exact package lists live in `packages/official.txt` and `packages/aur.txt`.

## Install

This currently targets Arch Linux. Install `yay` or `paru` first because four
appearance/desktop packages come from the AUR.

```bash
git clone https://github.com/Iris-NaN/camellia-niri-setup.git
cd camellia-niri-setup
./scripts/verify.sh
./install.sh --dry-run
./install.sh
```

The installer backs up replaced user configuration under:

```text
~/Backups/camellia-niri-setup/<timestamp>/
```

It also backs up the SDDM and locale files before system deployment.

Useful partial modes:

```bash
./install.sh --packages-only
./install.sh --configs-only
./install.sh --no-system
./install.sh --no-sddm-theme
./install.sh --locale zh_CN.UTF-8
./install.sh --replace-configs
```

The default is deliberately conservative:

- The existing system locale is preserved unless `--locale` is provided.
- Existing managed config directories are merged after backup. Use
  `--replace-configs` for an exact replacement.
- Use `--no-sddm-theme` to keep the current login theme.
- Niri-specific user services are linked to `niri.service`; they do not start
  inside Plasma or a text login.

## Display layout

The default configuration does not contain output names, resolutions or
positions, so Niri can start safely on different hardware. After logging in:

```bash
niri msg outputs
```

Use `profiles/outputs-external-top-internal-bottom.kdl` as a reference if the
new machine also needs an external display above the internal panel. Copy and
adjust its output blocks in `config.kdl`. The power-saver configuration is
generated from the main configuration automatically.

## Hardware adaptation

- The low-battery service is installed only when a battery is detected, and it
  discovers the UPower battery path instead of assuming `BAT0` or `BAT1`.
- Laptop backlights use `brightnessctl`; external monitors use `ddcutil`.
- For multiple DDC/CI monitors, set `DDCUTIL_DISPLAY` to the desired ddcutil
  display number before invoking the brightness helper.
- Battery and backlight Waybar modules hide themselves when the corresponding
  hardware is unavailable.

## Wallpapers and dynamic colors

Put wallpapers in `~/Pictures/Wallpapers`. One default image is bundled. The
existing Pywal workflow remains the color source; the installer recreates its
Waybar, Kitty, Rofi, SwayNC and Wlogout links for the target user's home.

## What is intentionally excluded

- Generated Pywal and thumbnail caches
- Git history and old configuration backups
- Browser profiles, cookies, passwords and personal data
- Current battery state and hardware identifiers
- Hard-coded monitor names and positions

## Verification

Run `./scripts/verify.sh`. It checks every shell script, verifies that referenced
Niri helper scripts exist, regenerates the power-saver config, and validates both
KDL files when `niri` is installed.
