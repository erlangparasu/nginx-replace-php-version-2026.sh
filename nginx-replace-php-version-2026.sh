#!/usr/bin/env bash

set -euo pipefail

TARGET_DIR="/etc/nginx/sites-enabled"
TARGET_VERSION="8.2"

usage() {
    echo "Usage: $0 [--dry-run | --fix]"
    echo "  --dry-run   Simulate updates without modifying files."
    echo "  --fix       Update PHP versions < 8.2 to 8.2 in Nginx configurations."
    exit 1
}

if [ "$#" -ne 1 ]; then
    usage
fi

MODE=""
case "$1" in
    --dry-run) MODE="dry-run" ;;
    --fix)     MODE="fix" ;;
    *)         usage ;;
esac

if [ "$MODE" = "fix" ] && [ "$(id -u)" -ne 0 ]; then
    echo "Error: --fix requires root privileges (sudo)." >&2
    exit 1
fi

if [ ! -d "$TARGET_DIR" ]; then
    echo "Error: Directory '$TARGET_DIR' does not exist." >&2
    exit 1
fi

echo "=================================================="
echo " Nginx PHP Version Updater"
echo " Target Directory: $TARGET_DIR"
echo " Target Threshold: PHP $TARGET_VERSION"
echo " Execution Mode:   $MODE"
echo "=================================================="

# Returns 0 if $1 < $2, otherwise 1
is_lower_version() {
    local v1_major v1_minor v2_major v2_minor
    IFS='.' read -r v1_major v1_minor <<< "$1"
    IFS='.' read -r v2_major v2_minor <<< "$2"

    if (( v1_major < v2_major )); then
        return 0
    elif (( v1_major == v2_major && v1_minor < v2_minor )); then
        return 0
    fi
    return 1
}

# In-place version replacer for versions lower than TARGET_VERSION
replace_php_version() {
    local file="$1"
    local target_ver="$2"
    local tmp_file
    tmp_file=$(mktemp)

    awk -v target="$target_ver" '
    {
        line = $0
        while (match(line, /php[0-9]+\.[0-9]+/)) {
            match_str = substr(line, RSTART, RLENGTH)
            ver = substr(match_str, 4)
            split(ver, v1, ".")
            split(target, v2, ".")

            v1_maj = v1[1] + 0; v1_min = v1[2] + 0
            v2_maj = v2[1] + 0; v2_min = v2[2] + 0

            if (v1_maj < v2_maj || (v1_maj == v2_maj && v1_min < v2_min)) {
                sub(/php[0-9]+\.[0-9]+/, "php" target, line)
            } else {
                gsub(match_str, "___SKIP___" ver, line)
            }
        }
        gsub(/___SKIP___/, "php", line)
        print line
    }' "$file" > "$tmp_file"

    mv "$tmp_file" "$file"
}

modified_files=0

for file in "$TARGET_DIR"/*; do
    # Dereference symlinks or read plain files
    [ -f "$file" ] || continue

    # Extract unique PHP versions present in config (e.g. php7.4, php8.1, php8.4)
    php_matches=$(grep -oE 'php[0-9]+\.[0-9]+' "$file" | sort -u || true)

    if [ -z "$php_matches" ]; then
        continue
    fi

    file_has_updates=0

    for match in $php_matches; do
        ver="${match#php}"
        if is_lower_version "$ver" "$TARGET_VERSION"; then
            echo "[MATCH] $file -> $match (< $TARGET_VERSION)"
            file_has_updates=1
        else
            echo "[KEEP]  $file -> $match (>= $TARGET_VERSION)"
        fi
    done

    if [ "$file_has_updates" -eq 1 ]; then
        modified_files=$((modified_files + 1))
        if [ "$MODE" = "dry-run" ]; then
            echo "  └─> [DRY-RUN] Would update $file to php${TARGET_VERSION}"
        elif [ "$MODE" = "fix" ]; then
            echo "  └─> [FIX] Updating $file..."
            replace_php_version "$file" "$TARGET_VERSION"
            echo "  └─> [FIX] Updated."
        fi
    fi
    echo ""
done

echo "=================================================="
echo "Summary: $modified_files file(s) identified for update."
echo "=================================================="

if [ "$MODE" = "fix" ] && [ "$modified_files" -gt 0 ]; then
    echo "Running Nginx syntax check..."
    if nginx -t; then
        echo "Nginx configuration syntax is valid."
        echo "Run 'systemctl reload nginx' to apply changes."
    else
        echo "Nginx configuration syntax error detected!" >&2
        exit 1
    fi
fi
