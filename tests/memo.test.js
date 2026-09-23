// Unit tests for plasmoid/bsums.xyz.memos-todo/contents/code/memo.js.
// Run with tests/run-tests.sh, or: node tests/memo.test.js
"use strict";

const assert = require("assert");
const fs = require("fs");
const path = require("path");
const vm = require("vm");

// memo.js is a QML JavaScript library. Drop its ".pragma library" line and
// run it in a fresh context to get its functions.
const source = fs.readFileSync(
    path.join(__dirname, "../plasmoid/bsums.xyz.memos-todo/contents/code/memo.js"), "utf8")
    .replace(/^\.pragma library\s*$/m, "");
const Memo = {};
vm.createContext(Memo);
vm.runInContext(source, Memo);

const SAMPLE = [
    "Shopping for the weekend",
    "☑ Do a little dance",
    "",
    "  ☐ Get down tonight  ",
    "a note under the task",
    "☐ Buy milk",
].join("\n");

let passed = 0;
let failed = 0;
function test(name, fn) {
    try {
        fn();
        passed++;
        console.log("ok   " + name);
    } catch (e) {
        failed++;
        console.log("FAIL " + name + "\n     " + e.message.split("\n").join("\n     "));
    }
}

test("parseItems groups text, to-do items and continuation lines", () => {
    const items = Memo.parseItems(SAMPLE);
    assert.deepStrictEqual(JSON.parse(JSON.stringify(items)), [
        { type: "text", checked: false, lines: ["Shopping for the weekend"] },
        { type: "todo", checked: true, lines: ["☑ Do a little dance"] },
        { type: "todo", checked: false, lines: ["☐ Get down tonight", "a note under the task"] },
        { type: "todo", checked: false, lines: ["☐ Buy milk"] },
    ]);
});

test("parseItems accepts empty and missing content", () => {
    assert.strictEqual(Memo.parseItems("").length, 0);
    assert.strictEqual(Memo.parseItems(undefined).length, 0);
    assert.strictEqual(Memo.parseItems("\n  \n").length, 0);
});

test("a checkbox character without a space is not a to-do item", () => {
    const items = Memo.parseItems("☐no space");
    assert.strictEqual(items[0].type, "text");
});

test("serialize round-trips trimmed content without blank lines", () => {
    assert.strictEqual(Memo.serialize(Memo.parseItems(SAMPLE)), [
        "Shopping for the weekend",
        "☑ Do a little dance",
        "☐ Get down tonight",
        "a note under the task",
        "☐ Buy milk",
    ].join("\n"));
});

test("toggleItem checks and unchecks, and keeps the text", () => {
    const items = Memo.parseItems(SAMPLE);
    const once = Memo.toggleItem(items, 2);
    assert.strictEqual(once[2].checked, true);
    assert.strictEqual(once[2].lines[0], "☑ Get down tonight");
    assert.strictEqual(once[2].lines[1], "a note under the task");
    const twice = Memo.toggleItem(once, 2);
    assert.strictEqual(twice[2].lines[0], "☐ Get down tonight");
});

test("toggleItem does not change the input or a text item", () => {
    const items = Memo.parseItems(SAMPLE);
    Memo.toggleItem(items, 2);
    assert.strictEqual(items[2].checked, false);
    assert.strictEqual(Memo.serialize(Memo.toggleItem(items, 0)), Memo.serialize(items));
});

test("removeItem removes a to-do item with its continuation lines", () => {
    const result = Memo.serialize(Memo.removeItem(Memo.parseItems(SAMPLE), 2));
    assert.strictEqual(result, "Shopping for the weekend\n☑ Do a little dance\n☐ Buy milk");
});

test("addItem appends an unchecked to-do item", () => {
    const result = Memo.addItem(Memo.parseItems(SAMPLE), "  Walk the dog ");
    assert.strictEqual(result[result.length - 1].lines[0], "☐ Walk the dog");
    assert.strictEqual(Memo.serialize(Memo.addItem([], "First")), "☐ First");
});

// The Cinnamon applet dropped hidden completed items from its item list,
// so the next save deleted them from the server. Here the item list always
// holds every item and only the view hides them.
test("changes keep completed items that the popup hides", () => {
    const items = Memo.parseItems(SAMPLE);
    const saved = Memo.serialize(Memo.addItem(Memo.toggleItem(items, 3), "New"));
    assert.ok(saved.includes("☑ Do a little dance"));
});

test("panelLines keeps every non-blank line, or leaves out completed lines", () => {
    assert.strictEqual(Memo.panelLines(SAMPLE, true).length, 5);
    assert.deepStrictEqual(Array.from(Memo.panelLines(SAMPLE, false)), [
        "Shopping for the weekend",
        "☐ Get down tonight",
        "a note under the task",
        "☐ Buy milk",
    ]);
});

test("shortenLine limits panel text to 100 characters", () => {
    assert.strictEqual(Memo.shortenLine("short"), "short");
    const long = "x".repeat(150);
    assert.strictEqual(Memo.shortenLine(long).length, 100);
    assert.ok(Memo.shortenLine(long).endsWith("..."));
});

test("contentFromResponse reads content and memo.content", () => {
    assert.strictEqual(Memo.contentFromResponse('{"content":"a"}'), "a");
    assert.strictEqual(Memo.contentFromResponse('{"memo":{"content":"b"}}'), "b");
    assert.strictEqual(Memo.contentFromResponse('{"name":"memos/1"}'), "");
    assert.throws(() => Memo.contentFromResponse("<html>"));
    assert.throws(() => Memo.contentFromResponse("null"));
});

test("URLs drop trailing slashes and spaces", () => {
    assert.strictEqual(Memo.apiUrl(" https://m.example.com// ", " 42 "), "https://m.example.com/api/v1/memos/42");
    assert.strictEqual(Memo.webUrl("https://m.example.com/", "42"), "https://m.example.com/memos/42");
});

console.log(`\n${passed} passed, ${failed} failed`);
process.exit(failed ? 1 : 0);
