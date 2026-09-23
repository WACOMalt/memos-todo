#!/bin/sh
# Memos ToDo installation script for KDE Plasma 6.
# Installs to user directories only. Does not use sudo.
set -e

REPO_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
SRC="$REPO_DIR/plasmoid/bsums.xyz.memos-todo"

if ! command -v kpackagetool6 >/dev/null 2>&1; then
    echo "kpackagetool6 not found. Install KDE Plasma 6, then run this script again."
    exit 1
fi

"$REPO_DIR/build-translations.sh"

echo "Installing the Plasma widget..."
kpackagetool6 -t Plasma/Applet -i "$SRC" 2>/dev/null \
    || kpackagetool6 -t Plasma/Applet -u "$SRC"

echo
echo "Installation complete. Next steps:"
echo "1. Restart Plasma: systemctl --user restart plasma-plasmashell.service"
echo "2. Right-click the panel, select \"Add Widgets\", and add \"Memos ToDo\"."
echo "3. Right-click the widget, select \"Configure Memos ToDo\", and enter"
echo "   your server URL, access token and memo ID."
