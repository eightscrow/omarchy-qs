#!/usr/bin/env bash

set -euo pipefail

detect_distro() {
    local os_release="/etc/os-release"
    local id=""
    local id_like=""

    [[ -f "$os_release" ]] || error "Missing /etc/os-release"

    # shellcheck disable=SC1091
    source "$os_release"

    id="${ID:-}"
    id_like="${ID_LIKE:-}"

    if [[ "$id" == "fedora" || "$id_like" == *"fedora"* ]]; then
        DISTRO_FAMILY="fedora"
        return 0
    fi

    if [[ "$id" == "arch" || "$id_like" == *"arch"* ]]; then
        DISTRO_FAMILY="arch"
        return 0
    fi

    error "Unsupported distro. Expected an Arch-based or Fedora-based Omarchy system."
}
