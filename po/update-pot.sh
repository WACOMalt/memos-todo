#!/bin/sh
# Extract the translatable strings of the widget into po/memos-todo.pot and
# merge them into each po/<language>.po file.
set -e
PO_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
SRC="$PO_DIR/../plasmoid/bsums.xyz.memos-todo/contents"
POT="$PO_DIR/memos-todo.pot"

(cd "$SRC" && find . -name '*.qml' -o -name '*.js' | sort) > "$PO_DIR/.files"
xgettext --from-code=UTF-8 -C --qt --no-location \
    -ki18n:1 -ki18nc:1c,2 -ki18np:1,2 -ki18ncp:1c,2,3 \
    --package-name="Memos ToDo" --msgid-bugs-address="https://github.com/WACOMalt/memos-todo/issues" \
    -D "$SRC" -f "$PO_DIR/.files" -o "$POT"
rm -f "$PO_DIR/.files"

for po in "$PO_DIR"/*.po; do
    msgmerge --quiet --update --backup=none --no-fuzzy-matching "$po" "$POT"
done
echo "Updated: $POT"
