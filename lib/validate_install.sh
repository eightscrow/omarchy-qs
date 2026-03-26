#!/usr/bin/env bash

set -euo pipefail

start_overview_instance() {
    if qs --path "$HOME/.config/quickshell/overview" list --all 2>/dev/null | grep -q '^Instance '; then
        qs kill -p "$HOME/.config/quickshell/overview" >/dev/null 2>&1 || true
    fi

    qs -p "$HOME/.config/quickshell/overview" -d >/dev/null 2>&1 || error "Failed to start Quickshell overview"
    sleep 1.5
}

validate_install() {
    require_command qs

    [[ -d "$HOME/.config/quickshell/overview" ]] || error "Overview directory was not installed"
    [[ -f "$HOME/.config/hypr/autostart.conf" ]] || error "Hyprland autostart.conf is missing"
    [[ -f "$HOME/.config/hypr/bindings.conf" ]] || error "Hyprland bindings.conf is missing"
    [[ -f "$HOME/.config/omarchy/hooks/theme-set.d/45-quickshell.sh" ]] || error "Theme hook was not installed"

    start_overview_instance

    qs --path "$HOME/.config/quickshell/overview" list --all 2>/dev/null | grep -q '^Instance ' || error "Overview instance is not running after install"

    success "Validation passed"
}
