#!/bin/bash

input_file="$HOME/.config/omarchy/current/theme/colors.toml"
overview_dir="$HOME/.config/quickshell/overview"
output_file="$overview_dir/common/Appearance.colors.qml"

if ! declare -F success >/dev/null 2>&1; then
    success() {
        echo -e "\e[32m[SUCCESS]\e[0m $1"
    }
fi

if ! declare -F skipped >/dev/null 2>&1; then
    skipped() {
        echo -e "\033[0;34m[SKIPPED]\e[0m $1 not found. Skipping.."
        exit 0
    }
fi

if ! declare -F error >/dev/null 2>&1; then
    error() {
        echo -e "\e[31m[ERROR]\e[0m $1"
        exit 1
    }
fi

if [[ ! -d "$overview_dir" ]]; then
    skipped "Quickshell overview"
fi

if [[ ! -f "$input_file" ]]; then
    error "colors.toml not found at $input_file"
fi

extract_color() {
    local color_name="$1"
    awk -v color="$color_name" '
        $1 == color && /=/ {
            if (match($0, /#([0-9a-fA-F]{6})/)) {
                print substr($0, RSTART + 1, 6)
                exit
            }
        }
    ' "$input_file"
}

clamp_channel() {
    local value="$1"
    if (( value < 0 )); then
        value=0
    elif (( value > 255 )); then
        value=255
    fi
    echo "$value"
}

hex_to_rgb() {
    local hex="$1"
    echo "$((16#${hex:0:2})) $((16#${hex:2:2})) $((16#${hex:4:2}))"
}

rgb_to_hex() {
    printf "%02x%02x%02x" "$1" "$2" "$3"
}

shade_hex() {
    local hex="$1"
    local delta="$2"
    read -r r g b <<< "$(hex_to_rgb "$hex")"
    r=$(clamp_channel $((r + delta)))
    g=$(clamp_channel $((g + delta)))
    b=$(clamp_channel $((b + delta)))
    rgb_to_hex "$r" "$g" "$b"
}

mix_hex() {
    local base="$1"
    local accent="$2"
    local accent_weight="$3"
    local base_weight=$((100 - accent_weight))
    read -r br bg bb <<< "$(hex_to_rgb "$base")"
    read -r ar ag ab <<< "$(hex_to_rgb "$accent")"
    local r=$(((br * base_weight + ar * accent_weight) / 100))
    local g=$(((bg * base_weight + ag * accent_weight) / 100))
    local b=$(((bb * base_weight + ab * accent_weight) / 100))
    rgb_to_hex "$r" "$g" "$b"
}

best_on_color() {
    local hex="$1"
    read -r r g b <<< "$(hex_to_rgb "$hex")"
    local yiq=$(((r * 299 + g * 587 + b * 114) / 1000))
    if (( yiq >= 140 )); then
        echo "121212"
    else
        echo "f5f5f5"
    fi
}

background="$(extract_color background)"
foreground="$(extract_color foreground)"
accent="$(extract_color accent)"
base_variant="$(extract_color color0)"
secondary="$(extract_color color13)"

if [[ -z "$background" || -z "$foreground" ]]; then
    error "Failed to extract required colors from $input_file"
fi

if [[ -z "$accent" ]]; then
    accent="$(extract_color color12)"
fi

if [[ -z "$secondary" ]]; then
    secondary="$accent"
fi

if [[ -z "$base_variant" ]]; then
    base_variant="$foreground"
fi

primary_container="$(mix_hex "$background" "$accent" 32)"
secondary_container="$(mix_hex "$background" "$secondary" 24)"
surface_low="$(shade_hex "$background" 6)"
surface="$(shade_hex "$background" 2)"
surface_container="$(shade_hex "$background" 10)"
surface_high="$(shade_hex "$background" 18)"
surface_highest="$(shade_hex "$background" 26)"
surface_variant="$(mix_hex "$background" "$base_variant" 55)"
outline="$(mix_hex "$background" "$foreground" 42)"
outline_variant="$(mix_hex "$background" "$base_variant" 35)"

mkdir -p "$(dirname "$output_file")"

cat > "$output_file" <<EOF
import QtQuick

QtObject {
    id: m3

    property color m3primary: "#${accent}"
    property color m3onPrimary: "#$(best_on_color "$accent")"

    property color m3primaryContainer: "#${primary_container}"
    property color m3onPrimaryContainer: "#$(best_on_color "$primary_container")"

    property color m3secondary: "#${secondary}"
    property color m3onSecondary: "#$(best_on_color "$secondary")"

    property color m3secondaryContainer: "#${secondary_container}"
    property color m3onSecondaryContainer: "#$(best_on_color "$secondary_container")"

    property color m3background: "#${background}"
    property color m3onBackground: "#${foreground}"

    property color m3surface: "#${surface}"

    property color m3surfaceContainerLow: "#${surface_low}"
    property color m3surfaceContainer: "#${surface_container}"
    property color m3surfaceContainerHigh: "#${surface_high}"
    property color m3surfaceContainerHighest: "#${surface_highest}"

    property color m3onSurface: "#${foreground}"

    property color m3surfaceVariant: "#${surface_variant}"
    property color m3onSurfaceVariant: "#$(mix_hex "$background" "$foreground" 74)"

    property color m3inverseSurface: "#${foreground}"
    property color m3inverseOnSurface: "#${background}"

    property color m3outline: "#${outline}"
    property color m3outlineVariant: "#${outline_variant}"

    property color m3shadow: "#000000"
}
EOF

if qs --path "$overview_dir" list --all 2>/dev/null | grep -q '^Instance '; then
    qs kill -p "$overview_dir" >/dev/null 2>&1 || true
    sleep 0.3
    qs -p "$overview_dir" -d >/dev/null 2>&1 || true
fi

success "Quickshell overview theme updated!"
exit 0