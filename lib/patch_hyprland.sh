#!/usr/bin/env bash

set -euo pipefail

patch_hyprland_config() {
    local autostart_file="$HOME/.config/hypr/autostart.conf"
    local bindings_file="$HOME/.config/hypr/bindings.conf"
    local autostart_block='exec-once = qs -p ~/.config/quickshell/overview'
    local binding_block='unbind = SUPER, D
bindd = SUPER, D, Workspace Overview, exec, qs -p ~/.config/quickshell/overview ipc call overview toggle'

    [[ -f "$autostart_file" ]] && backup_path "$autostart_file"
    [[ -f "$bindings_file" ]] && backup_path "$bindings_file"

    upsert_managed_block "$autostart_file" "omarchy-qs-autostart" "$autostart_block"
    upsert_managed_block "$bindings_file" "omarchy-qs-bindings" "$binding_block"

    success "Patched Hyprland user config"
}
