#!/bin/sh
# Run the Memos ToDo tests. Needs Node.js. Does not need a Memos server.
set -e
TESTS_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
node "$TESTS_DIR/memo.test.js"
