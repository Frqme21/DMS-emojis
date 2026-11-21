#!/usr/bin/env bash
set -e

PLUGIN_DIR="$HOME/.config/dms/plugins/EmojiShortcode"
REPO_URL="https://github.com/Frqme21/DMS-emojis.git"

mkdir -p "$HOME/.config/dms/plugins"

if [ -d "$PLUGIN_DIR/.git" ]; then
    echo "Updating EmojiShortcode..."
    git -C "$PLUGIN_DIR" pull --ff-only
else
    rm -rf "$PLUGIN_DIR"
    echo "Installing EmojiShortcode..."
    git clone --depth 1 "$REPO_URL" "$PLUGIN_DIR"
fi

dms restart >/dev/null 2>&1 || true
echo "Done! Enable 'Emoji Shortcodes' in DMS Settings -> Plugins."
