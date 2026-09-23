#!/bin/sh
# Compile po/<language>.po into the widget package, as
# contents/locale/<language>/LC_MESSAGES/plasma_applet_<id>.mo.
set -e

REPO_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
SRC="$REPO_DIR/plasmoid/bsums.xyz.memos-todo"
DOMAIN="plasma_applet_bsums.xyz.memos-todo"

if ! command -v msgfmt >/dev/null 2>&1; then
    echo "msgfmt not found (package gettext). The widget is built without translations."
    exit 0
fi

rm -rf "$SRC/contents/locale"
for po in "$REPO_DIR"/po/*.po; do
    lang=$(basename "$po" .po)
    mkdir -p "$SRC/contents/locale/$lang/LC_MESSAGES"
    msgfmt --check -o "$SRC/contents/locale/$lang/LC_MESSAGES/$DOMAIN.mo" "$po"
done
