#!/usr/bin/env bash

set -euo pipefail

install_overview_assets() {
    local repo_root="$1"
    local source_dir="$repo_root/assets/quickshell/overview"
    local target_dir="$HOME/.config/quickshell/overview"

    [[ -d "$source_dir" ]] || error "Missing overview assets at $source_dir"

    if [[ -d "$target_dir" ]]; then
        backup_path "$target_dir"
    fi

    mkdir -p "$target_dir"
    cp -a "$source_dir/." "$target_dir/"
    success "Installed overview assets to $target_dir"
}
