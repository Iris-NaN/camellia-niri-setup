#!/usr/bin/env bash

set -euo pipefail

root_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
install_packages=1
install_configs=1
install_system=1
export INSTALL_SDDM_THEME=1
export REPLACE_CONFIGS=0
export SYSTEM_LOCALE=""

usage() {
    cat <<'EOF'
Usage: ./install.sh [options]

  --dry-run        Print actions without changing the system
  --packages-only  Install packages only
  --configs-only   Deploy user configuration only
  --no-system      Skip SDDM, locale and system service setup
  --no-sddm-theme  Preserve the currently configured SDDM theme
  --locale LOCALE  Set the system locale explicitly (example: zh_CN.UTF-8)
  --replace-configs
                   Replace managed config directories after backing them up
  -h, --help       Show this help
EOF
}

while (($#)); do
    case $1 in
        --dry-run) export DRY_RUN=1 ;;
        --packages-only) install_configs=0; install_system=0 ;;
        --configs-only) install_packages=0; install_system=0 ;;
        --no-system) install_system=0 ;;
        --no-sddm-theme) export INSTALL_SDDM_THEME=0 ;;
        --replace-configs) export REPLACE_CONFIGS=1 ;;
        --locale)
            shift
            [[ $# -gt 0 ]] || { printf '%s\n' '--locale requires a value.' >&2; exit 64; }
            [[ $1 =~ ^[A-Za-z_]+\.[A-Za-z0-9-]+$ ]] || {
                printf 'Invalid locale: %s\n' "$1" >&2
                exit 64
            }
            export SYSTEM_LOCALE=$1
            ;;
        -h|--help) usage; exit 0 ;;
        *) printf 'Unknown option: %s\n' "$1" >&2; usage >&2; exit 64 ;;
    esac
    shift
done

(( install_packages )) && "$root_dir/scripts/install-packages.sh"
(( install_configs )) && "$root_dir/scripts/deploy-user-config.sh"
(( install_system )) && "$root_dir/scripts/deploy-system-config.sh"

printf '\nInstallation finished. Reboot or log out, then choose Niri in SDDM.\n'
