# Camellia Niri Setup

Reproduce this Arch Linux Niri desktop on another computer with a small,
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
git clone <your-repository-url> camellia-niri-setup
cd camellia-niri-setup
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
```

## Display layout

The default configuration does not contain output names, resolutions or
positions, so Niri can start safely on different hardware. After logging in:

```bash
niri msg outputs
```

Use `profiles/outputs-external-top-internal-bottom.kdl` as a reference if the
new machine also needs an external display above the internal panel. Copy and
adjust its output blocks in both `config.kdl` and `config-power-saver.kdl`.

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

```bash
bash -n install.sh scripts/*.sh
niri validate -c dotfiles/.config/niri/config.kdl
niri validate -c dotfiles/.config/niri/config-power-saver.kdl
```
