#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=lib/common.sh
source "$repo_root/lib/common.sh"

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    echo "Usage: ./uninstall.sh"
    exit 0
fi

backup_path "$HOME/.config/hypr/autostart.conf"
backup_path "$HOME/.config/hypr/bindings.conf"
backup_path "$HOME/.config/omarchy/hooks/theme-set"

remove_managed_block "$HOME/.config/hypr/autostart.conf" "omarchy-qs-autostart"
remove_managed_block "$HOME/.config/hypr/bindings.conf" "omarchy-qs-bindings"
remove_managed_block "$HOME/.config/omarchy/hooks/theme-set" "omarchy-qs-theme-hooks"

if [[ -f "$HOME/.config/omarchy/hooks/theme-set.d/45-quickshell.sh" ]]; then
    backup_path "$HOME/.config/omarchy/hooks/theme-set.d/45-quickshell.sh"
    rm -f "$HOME/.config/omarchy/hooks/theme-set.d/45-quickshell.sh"
fi

if [[ -d "$HOME/.config/quickshell/overview" ]]; then
    backup_path "$HOME/.config/quickshell/overview"
    rm -rf "$HOME/.config/quickshell/overview"
fi

success "omarchy-qs uninstall finished"