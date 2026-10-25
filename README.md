# Camellia Niri Setup

[English](README.md) | [简体中文](README_zh.md)

Reproduce this Arch Linux Niri desktop on another computer with a self-contained,
auditable installer. The project is inspired by `niriconf`, but avoids cached
state, destructive uninstall steps, and machine-specific output names.

## Included software

- Graphical core: Niri, Kanshi, Waybar, SwayNC, Fuzzel/Rofi, Kitty, portals
  and Polkit
- Login: SDDM with the bundled SilentSDDM theme
- Appearance: Layan Dark, Papirus Dark, Bibata cursor, Pywal dynamic colors
- Files: Thunar, GVfs, Tumbler and Ark
- Browser: Firefox Developer Edition with Simplified Chinese language pack
- Input: Fcitx5 with Chinese addons
- Basics: NetworkManager, PipeWire, Bluetooth, clipboard, brightness, media,
  screenshots, power profiles, monitoring and common CLI utilities

Exact package lists live in `packages/official.txt` and `packages/aur.txt`.

## Install

This currently targets Arch Linux. Install `yay` or `paru` first because five
packages, including Pywal, come from the AUR. The installer installs the
`base-devel` prerequisite automatically.

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
- AUR package failures are reported but do not prevent user configs, SDDM, or
  system services from being deployed. Features that depend on those packages,
  such as dynamic colors, screen locking, or the power menu, may be unavailable.

If GitHub downloads used by AUR packages are blocked, pass a trusted HTTPS
proxy to the installer. Both spellings are set because Git and curl may consult
different environment variables:

```bash
https_proxy=http://127.0.0.1:7890 \
HTTPS_PROXY=http://127.0.0.1:7890 \
./install.sh
```

Inside a VM, `127.0.0.1` is the guest itself. If the proxy runs on the libvirt
host, use the host-side bridge address instead (commonly `192.168.122.1`) and
make sure the proxy listens on that interface. Restrict it to the VM network;
do not expose an unauthenticated proxy on other interfaces.

Do not disable TLS verification or replace PKGBUILD source URLs with an
untrusted download proxy. AUR source hashes and signatures should still be
verified normally.

## QEMU/KVM virtual machines

Niri requires a working hardware EGL/GBM renderer and deliberately rejects
llvmpipe/softpipe software EGL renderers. For a libvirt VM, use a Virtio video
device with 3D acceleration and enable OpenGL on the SPICE display. With the VM
shut down, the equivalent commands are:

```bash
virt-xml VM_NAME --edit --video model.acceleration.accel3d=yes
virt-xml VM_NAME --edit --graphics gl.enable=yes,listen=none
```

Fully power the guest off and start it again; rebooting only the guest kernel
does not recreate the virtual GPU. Recent libvirt versions record the selected
Virtio frontend in a `device` attribute. For an existing VM, inspect the
inactive XML:

```bash
virsh dumpxml --inactive VM_NAME
```

If the accelerated video model is still recorded as `device='virtio-vga'`,
change that attribute to `device='virtio-vga-gl'` with `virsh edit VM_NAME`,
while keeping `<acceleration accel3d='yes'/>`. After starting the VM, verify the
guest kernel rather than trusting the checkbox alone:

```bash
journalctl -b -k | grep -E 'features:|cap sets'
```

A working VirGL device reports `features: +virgl` and at least one capability
set. `features: -virgl` means QEMU still created a 2D-only Virtio GPU.

The host needs QEMU, Mesa and `virglrenderer`. If the Niri journal contains
`software EGL renderers are skipped` or `no allocator available for device`,
the VM is still using software rendering. Some framebuffer screenshot tools
show a black image with SPICE GL even when virt-manager displays the desktop
correctly.

## Display layout and hotplug

Kanshi starts with the Niri session and reads `~/.config/kanshi/config`. Its
portable fallback enables every connected output while leaving mode, position,
scale, transform, VRR, and HDR to Niri. No output names or machine-specific
values are baked into the default configuration.

Useful commands:

```bash
niri msg outputs         # connector names and monitor descriptions
kanshictl status         # active Kanshi profile
kanshictl reload         # reload after editing ~/.config/kanshi/config
```

For a fixed desk, add a specific profile above the `fallback` profile in
`~/.config/kanshi/config`. Kanshi chooses the first profile that covers every
currently connected output, so docked and undocked setups can coexist.
Prefer stable manufacturer/model/serial descriptions when connector names
change.

`profiles/outputs-external-top-internal-bottom.kdl` is still available as a
static Niri-only alternative for a permanently wired external display above
the internal panel. Use either a Kanshi profile or static Niri output blocks
for the same output properties, not both.

The power-saver configuration is generated from the main Niri configuration
automatically.

## Hardware adaptation

- The low-battery service is installed only when a battery is detected, and it
  discovers the UPower battery path instead of assuming `BAT0` or `BAT1`.
- Laptop backlights use `brightnessctl`; external monitors use `ddcutil`.
- For multiple DDC/CI monitors, set `DDCUTIL_DISPLAY` to the desired ddcutil
  display number before invoking the brightness helper.
- Battery and backlight Waybar modules hide themselves when the corresponding
  hardware is unavailable.

For the machine these dotfiles were tuned on, `docs/hardware.en.md` records the
drivers in use, the kernel command line, the wireless regulatory domain setup and
the hardware limitations that cannot be fixed from the configuration side.

## Lock screen and idle behaviour

`Mod+L` runs the `lock-screen.sh` helper, which locks the session with swaylock
and only then powers the monitors off, so the desktop is never visible without
the lock screen. Niri powers the monitors back on as soon as the session
receives input or is unlocked.

The `swayidle` service mirrors that behaviour:

- `timeout 600` locks the session, `timeout 900` turns the monitors off.
- `lock` handles session lock requests from any client, including `Mod+L`, and
  `before-sleep` turns the monitors off before suspending.

## Wallpapers and dynamic colors

Put wallpapers in `~/Pictures/Wallpapers`. One default image is bundled. Static
JPG/JPEG/PNG wallpapers are supported; animated GIF wallpapers are intentionally
omitted along with the `mpvpaper` dependency. The existing Pywal workflow
remains the color source; the installer recreates its
Waybar, Kitty, Rofi, SwayNC and Wlogout links for the target user's home. It
also regenerates the complete btop theme whenever the wallpaper palette
changes.

## What is intentionally excluded

- Generated Pywal and thumbnail caches
- Git history and old configuration backups
- Browser profiles, cookies, passwords and personal data
- Current battery state and hardware identifiers
- Hard-coded monitor names and positions

## Verification

Run `./scripts/verify.sh`. It checks every shell script, verifies that referenced
Niri helper scripts exist, regenerates the power-saver config, validates both KDL
files when `niri` is installed, and validates the Kanshi profile when `kanshi` is
installed.

Run `./scripts/verify-drivers.sh` to check the machine itself. It is read-only:
nothing is loaded, unloaded or reconfigured, and a section is skipped when the
matching hardware or tool is missing. It reports the driver behind the GPU,
wireless and backlight devices, plus the regulatory domain, bluetooth, audio,
camera, touchpad, sensors and CPU frequency scaling, and it fails when a driver
is missing or the kernel reports a firmware load failure.
