#!/usr/bin/env bash

set -euo pipefail

root_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
install_packages=1
install_configs=1
install_system=1

usage() {
    cat <<'EOF'
Usage: ./install.sh [options]

  --dry-run        Print actions without changing the system
  --packages-only  Install packages only
  --configs-only   Deploy user configuration only
  --no-system      Skip SDDM, locale and system service setup
  -h, --help       Show this help
EOF
}

while (($#)); do
    case $1 in
        --dry-run) export DRY_RUN=1 ;;
        --packages-only) install_configs=0; install_system=0 ;;
        --configs-only) install_packages=0; install_system=0 ;;
        --no-system) install_system=0 ;;
        -h|--help) usage; exit 0 ;;
        *) printf 'Unknown option: %s\n' "$1" >&2; usage >&2; exit 64 ;;
    esac
    shift
done

(( install_packages )) && "$root_dir/scripts/install-packages.sh"
(( install_configs )) && "$root_dir/scripts/deploy-user-config.sh"
(( install_system )) && "$root_dir/scripts/deploy-system-config.sh"

printf '\nInstallation finished. Reboot or log out, then choose Niri in SDDM.\n'
