#!/usr/bin/env bash

set -euo pipefail

show_package_install_hint() {
    case "$1" in
        arch)
            error "Quickshell is missing. Install it with: sudo pacman -S --needed quickshell"
            ;;
        fedora)
            error "Quickshell is missing. Install it with: sudo dnf install quickshell"
            ;;
        *)
            error "Quickshell is missing and the distro family is unknown"
            ;;
    esac
}

install_quickshell_package() {
    case "$1" in
        arch)
            require_command sudo
            require_command pacman
            pacman -Si quickshell >/dev/null 2>&1 || error "quickshell is not available in current pacman repositories"
            sudo pacman -S --needed quickshell
            ;;
        fedora)
            require_command sudo
            require_command dnf
            dnf info quickshell >/dev/null 2>&1 || error "quickshell is not available in enabled dnf repositories"
            sudo dnf install -y quickshell
            ;;
        *)
            error "Unsupported distro family for package installation: $1"
            ;;
    esac
}
