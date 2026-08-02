#!/usr/bin/env bash
# Install this quickshell config to ~/.config/quickshell/ii
set -euo pipefail

src="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
dst_dir="${XDG_CONFIG_HOME:-$HOME/.config}/quickshell"
target="$dst_dir/ii"

mkdir -p "$dst_dir"

# If the target already exists and is not already a link to this repo, back it up
if [ -e "$target" ] || [ -L "$target" ]; then
    if [ "$(readlink -f "$target" 2>/dev/null)" = "$src" ]; then
        echo "Already installed: $target -> $src"
        exit 0
    fi
    backup="$target.bak.$(date +%s)"
    echo "Backing up existing $target -> $backup"
    mv "$target" "$backup"
fi

ln -sfn "$src" "$target"
echo "Installed: $target -> $src"
echo "Reload/launch Quickshell to apply (e.g. qs -p $target/shell.qml)."
