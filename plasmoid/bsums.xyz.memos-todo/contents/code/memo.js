.pragma library

// Memo parsing for Memos ToDo. This file has no QML dependencies, so
// tests/run-tests.sh can load it in Node as well.
//
// A memo holds one item per line. A line that starts with a checkbox
// character is a to-do item. The plain lines under a to-do item belong to
// it. Plain lines before the first to-do item form a text item. Every
// Memos ToDo client uses the same two checkbox characters.

var UNCHECKED = "☐ ";
var CHECKED = "☑ ";

function isTodoLine(line) {
    return line.startsWith(UNCHECKED) || line.startsWith(CHECKED);
}

// Returns the items of the memo content, in order. Each item is
// { type: "todo" | "text", checked: bool, lines: [string] }.
// Blank lines are dropped and each line is trimmed.
function parseItems(content) {
    var items = [];
    var current = null;
    var lines = (content || "").split("\n");
    for (var i = 0; i < lines.length; i++) {
        var line = lines[i].trim();
        if (line === "")
            continue;
        if (isTodoLine(line)) {
            current = { type: "todo", checked: line.startsWith(CHECKED), lines: [line] };
            items.push(current);
        } else if (current) {
            current.lines.push(line);
        } else {
            current = { type: "text", checked: false, lines: [line] };
            items.push(current);
        }
    }
    return items;
}

// Returns the memo content for the items. This is the text that goes back
// to the server, so it must hold every item, also the ones that the popup
// hides.
function serialize(items) {
    var lines = [];
    for (var i = 0; i < items.length; i++)
        lines = lines.concat(items[i].lines);
    return lines.join("\n");
}

function copyItems(items) {
    return items.map(function (item) {
        return { type: item.type, checked: item.checked, lines: item.lines.slice() };
    });
}

// Returns a copy of the items with the to-do item at index toggled.
function toggleItem(items, index) {
    var result = copyItems(items);
    var item = result[index];
    if (!item || item.type !== "todo")
        return result;
    item.checked = !item.checked;
    item.lines[0] = (item.checked ? CHECKED : UNCHECKED) + item.lines[0].substring(2);
    return result;
}

// Returns a copy of the items without the item at index.
function removeItem(items, index) {
    var result = copyItems(items);
    result.splice(index, 1);
    return result;
}

// Returns a copy of the items with a new unchecked to-do item at the end.
function addItem(items, text) {
    var result = copyItems(items);
    var line = UNCHECKED + text.trim();
    result.push({ type: "todo", checked: false, lines: [line] });
    return result;
}

// Returns the lines that the panel label cycles through. Each non-blank
// line is one entry. Completed to-do lines are left out when
// showCompleted is false.
function panelLines(content, showCompleted) {
    var lines = (content || "").split("\n")
        .map(function (l) { return l.trim(); })
        .filter(function (l) { return l.length > 0; });
    if (!showCompleted)
        lines = lines.filter(function (l) { return !l.startsWith(CHECKED); });
    return lines;
}

// Shortens a line for the panel label, as the Cinnamon applet does.
function shortenLine(line) {
    return line.length > 100 ? line.substring(0, 97) + "..." : line;
}

// Returns the content field of a memo API response. Throws if the text is
// not JSON.
function contentFromResponse(text) {
    var data = JSON.parse(text);
    if (!data)
        throw new Error("Null or empty JSON");
    return data.content || (data.memo && data.memo.content) || "";
}

function baseUrl(serverUrl) {
    return serverUrl.trim().replace(/\/+$/, "");
}

function apiUrl(serverUrl, memoId) {
    return baseUrl(serverUrl) + "/api/v1/memos/" + memoId.trim();
}

function webUrl(serverUrl, memoId) {
    return baseUrl(serverUrl) + "/memos/" + memoId.trim();
}
