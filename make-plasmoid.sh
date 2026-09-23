#!/bin/sh
# Build the .plasmoid package for the KDE Store.
# Output: dist/memos-todo-<version>.plasmoid
set -e

REPO_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
SRC="$REPO_DIR/plasmoid/bsums.xyz.memos-todo"
VERSION=$(grep -o '"Version": "[^"]*"' "$SRC/metadata.json" | cut -d'"' -f4)
OUT="$REPO_DIR/dist/memos-todo-$VERSION.plasmoid"

mkdir -p "$REPO_DIR/dist"
rm -f "$OUT"
# Compile the translations. Plasma loads them from contents/locale.
"$REPO_DIR/build-translations.sh"
# The KDE Store expects metadata.json at the root of the archive.
(cd "$SRC" && zip -qr "$OUT" metadata.json contents)
echo "Built: $OUT"
