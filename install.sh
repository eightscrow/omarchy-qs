#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=lib/common.sh
source "$repo_root/lib/common.sh"
# shellcheck source=lib/detect_distro.sh
source "$repo_root/lib/detect_distro.sh"
# shellcheck source=lib/install_assets.sh
source "$repo_root/lib/install_assets.sh"
# shellcheck source=lib/install_package.sh
source "$repo_root/lib/install_package.sh"
# shellcheck source=lib/install_theme_hook.sh
source "$repo_root/lib/install_theme_hook.sh"
# shellcheck source=lib/patch_hyprland.sh
source "$repo_root/lib/patch_hyprland.sh"
# shellcheck source=lib/validate_install.sh
source "$repo_root/lib/validate_install.sh"

usage() {
    cat <<'EOF'
Usage: ./install.sh

Options:
  -h, --help   Show this help message.
EOF
}

while (($# > 0)); do
    case "$1" in
        -h|--help)
            usage
            exit 0
            ;;
        *)
            error "Unknown argument: $1"
            ;;
    esac
    shift
done

detect_distro
info "Detected distro family: $DISTRO_FAMILY"

if ! command -v qs >/dev/null 2>&1; then
    install_quickshell_package "$DISTRO_FAMILY"
fi

install_overview_assets "$repo_root"
patch_hyprland_config
install_theme_hook "$repo_root"

# Apply current Omarchy theme colors immediately so qs starts with correct palette
hook_script="$HOME/.config/omarchy/hooks/theme-set.d/45-quickshell.sh"
if [[ -f "$hook_script" ]]; then
    bash "$hook_script" || true
fi

validate_install

success "omarchy-qs installation finished"
