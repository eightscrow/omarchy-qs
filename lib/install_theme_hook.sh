#!/usr/bin/env bash

set -euo pipefail

install_theme_hook() {
    local repo_root="$1"
    local hook_source="$repo_root/assets/omarchy/hooks/theme-set.d/45-quickshell.sh"
    local hook_target="$HOME/.config/omarchy/hooks/theme-set.d/45-quickshell.sh"
    local dispatcher="$HOME/.config/omarchy/hooks/theme-set"
    local dispatcher_block='if [[ -d ~/.config/omarchy/hooks/theme-set.d ]]; then
    for hook in ~/.config/omarchy/hooks/theme-set.d/*.sh; do
        if [[ -f "$hook" ]]; then
            if ! bash "$hook" "$@"; then
                error "Hook $(basename "$hook") failed!" >&2
            fi
        fi
    done
fi'

    [[ -f "$hook_source" ]] || error "Missing theme hook asset at $hook_source"

    mkdir -p "$(dirname "$hook_target")"
    if [[ -f "$hook_target" ]]; then
        backup_path "$hook_target"
    fi
    cp -a "$hook_source" "$hook_target"

    mkdir -p "$(dirname "$dispatcher")"
    touch "$dispatcher"

    if ! grep -Fq 'theme-set.d/*.sh' "$dispatcher"; then
        backup_path "$dispatcher"
        upsert_managed_block "$dispatcher" "omarchy-qs-theme-hooks" "$dispatcher_block"
    fi

    chmod +x "$hook_target" "$dispatcher"
    success "Installed Quickshell theme hook"
}
