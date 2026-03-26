#!/usr/bin/env bash

set -euo pipefail

info() {
    printf '[INFO] %s\n' "$1"
}

success() {
    printf '[OK] %s\n' "$1"
}

warning() {
    printf '[WARN] %s\n' "$1"
}

error() {
    printf '[ERROR] %s\n' "$1" >&2
    exit 1
}

require_command() {
    command -v "$1" >/dev/null 2>&1 || error "Required command not found: $1"
}

timestamp() {
    date +%Y%m%d-%H%M%S
}

backup_path() {
    local path="$1"
    local backup

    [[ -e "$path" ]] || return 0

    backup="${path}.bak.$(timestamp)"
    cp -a "$path" "$backup"
    info "Backed up $path to $backup"
}

upsert_managed_block() {
    local file="$1"
    local marker="$2"
    local body="$3"
    local start="# >>> ${marker} >>>"
    local end="# <<< ${marker} <<<"
    local block="${start}"$'\n'"${body}"$'\n'"${end}"
    local tmp

    mkdir -p "$(dirname "$file")"
    touch "$file"
    tmp="$(mktemp)"

    awk -v start="$start" -v end="$end" -v block="$block" '
        BEGIN {
            inblock = 0;
            replaced = 0;
        }
        $0 == start {
            if (!replaced)
                print block;
            inblock = 1;
            replaced = 1;
            next;
        }
        $0 == end {
            inblock = 0;
            next;
        }
        !inblock {
            print;
        }
        END {
            if (!replaced) {
                if (NR > 0)
                    print "";
                print block;
            }
        }
    ' "$file" > "$tmp"

    cat "$tmp" > "$file"
    rm -f "$tmp"
}

remove_managed_block() {
    local file="$1"
    local marker="$2"
    local start="# >>> ${marker} >>>"
    local end="# <<< ${marker} <<<"
    local tmp

    [[ -f "$file" ]] || return 0

    tmp="$(mktemp)"
    awk -v start="$start" -v end="$end" '
        BEGIN {
            inblock = 0;
        }
        $0 == start {
            inblock = 1;
            next;
        }
        $0 == end {
            inblock = 0;
            next;
        }
        !inblock {
            print;
        }
    ' "$file" > "$tmp"

    cat "$tmp" > "$file"
    rm -f "$tmp"
}
