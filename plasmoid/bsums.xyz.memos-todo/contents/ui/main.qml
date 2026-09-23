pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

import "../code/memo.js" as Memo

PlasmoidItem {
    id: root

    readonly property var cfg: Plasmoid.configuration

    readonly property bool configured: cfg.serverUrl.trim() !== ""
                                       && cfg.authToken.trim() !== ""
                                       && cfg.memoId.trim() !== ""

    // The last memo content that the server sent. It stays when a later
    // request fails, so the panel keeps the last known good lines.
    property string content: ""
    property bool loaded: false
    property var items: []
    property var panelLines: []
    property int lineIndex: 0

    // A message for the top of the popup: loading, an error, or a request
    // to configure the widget. Empty when there is nothing to report.
    property string statusText: i18n("Loading...")
    property bool hasError: false

    // Each request gets a serial number. A read that started before the
    // latest write can hold old content, so its result is ignored. Only
    // the response to the latest write updates the view.
    property int requestSerial: 0
    property int lastWriteSerial: 0

    readonly property int openCount: items.filter(item => item.type === "todo" && !item.checked).length
    readonly property int todoCount: items.filter(item => item.type === "todo").length

    // The text for the panel. Compare _updateAppletLabel in the Cinnamon
    // applet.
    readonly property string panelText: {
        if (!configured)
            return i18n("Configure Settings");
        if (panelLines.length === 0) {
            if (hasError)
                return statusText || i18n("Error");
            return loaded ? i18n("Empty Memo") : i18n("Loading...");
        }
        const index = lineIndex >= 0 && lineIndex < panelLines.length ? lineIndex : 0;
        return Memo.shortenLine(panelLines[index]);
    }

    Plasmoid.icon: "view-task"
    toolTipMainText: i18n("Memos ToDo")
    toolTipSubText: !configured ? i18n("Please configure Server URL, Token and Memo ID in settings.")
                  : hasError ? statusText
                  : !loaded ? i18n("Loading...")
                  : todoCount === 0 ? i18n("Empty Memo")
                  : i18np("%1 open task", "%1 open tasks", openCount)

    preferredRepresentation: compactRepresentation
    compactRepresentation: CompactRepresentation { app: root }
    fullRepresentation: FullRepresentation { app: root }

    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: i18n("Refresh")
            icon.name: "view-refresh"
            enabled: root.configured
            onTriggered: root.fetchMemo()
        },
        PlasmaCore.Action {
            text: i18n("Open in Browser")
            icon.name: "internet-web-browser"
            enabled: root.configured
            onTriggered: root.openInBrowser()
        }
    ]

    Timer {
        id: refreshTimer
        interval: Math.max(1, root.cfg.refreshInterval) * 60 * 1000
        repeat: true
        running: root.configured
        onTriggered: root.fetchMemo()
    }

    // Settings that change what the widget shows fetch the memo again, as
    // in the Cinnamon applet.
    Connections {
        target: root.cfg
        function onServerUrlChanged() { root.settingsChanged() }
        function onAuthTokenChanged() { root.settingsChanged() }
        function onMemoIdChanged() { root.settingsChanged() }
        function onRefreshIntervalChanged() { root.fetchMemo() }
        function onShowCompletedPanelChanged() { root.fetchMemo() }
        function onShowCompletedPopupChanged() { root.fetchMemo() }
    }

    // A different server or memo makes the old content wrong, so it goes.
    // The change often comes one key press at a time, so wait for a pause.
    function settingsChanged() {
        content = "";
        items = [];
        panelLines = [];
        loaded = false;
        settingsDelay.restart();
    }

    Timer {
        id: settingsDelay
        interval: 1000
        onTriggered: root.fetchMemo()
    }

    Component.onCompleted: fetchMemo()

    function applyContent(newContent) {
        content = newContent;
        items = Memo.parseItems(newContent);
        panelLines = Memo.panelLines(newContent, cfg.showCompletedPanel);
        if (lineIndex >= panelLines.length)
            lineIndex = 0;
        loaded = true;
        hasError = false;
        statusText = "";
    }

    // Moves the panel label to the next line.
    function nextLine() {
        lineIndex = panelLines.length > 0 ? (lineIndex + 1) % panelLines.length : 0;
    }

    function handleError(message) {
        hasError = true;
        statusText = message;
    }

    function request(method, body, onSuccess) {
        const serial = ++requestSerial;
        if (method !== "GET")
            lastWriteSerial = serial;

        const xhr = new XMLHttpRequest();
        xhr.open(method, Memo.apiUrl(cfg.serverUrl, cfg.memoId));
        xhr.setRequestHeader("Authorization", "Bearer " + cfg.authToken.trim());
        xhr.setRequestHeader("Accept", "application/json");
        if (body !== null)
            xhr.setRequestHeader("Content-Type", "application/json");
        xhr.onreadystatechange = () => {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;
            if (serial < lastWriteSerial)
                return;
            if (xhr.status === 0) {
                handleError(i18n("Connection Error"));
            } else if (xhr.status !== 200) {
                handleError(i18n("Error %1", xhr.status));
            } else {
                onSuccess(xhr.responseText);
            }
        };
        xhr.send(body);
    }

    function handleResponse(text) {
        let newContent;
        try {
            newContent = Memo.contentFromResponse(text);
        } catch (e) {
            console.warn("Memos ToDo: parse error:", e.message, "| Data:", String(text).substring(0, 100));
            handleError(i18n("Parse Error"));
            return;
        }
        applyContent(newContent);
    }

    function fetchMemo() {
        if (!configured) {
            hasError = false;
            statusText = i18n("Please configure Server URL, Token and Memo ID in settings.");
            return;
        }
        if (!loaded && !hasError)
            statusText = i18n("Loading...");
        request("GET", null, handleResponse);
    }

    // Shows the new items at once, then sends them to the server. The
    // server response replaces them when it comes.
    function saveItems(newItems) {
        if (!configured)
            return;
        const newContent = Memo.serialize(newItems);
        applyContent(newContent);
        request("PATCH", JSON.stringify({ content: newContent }), handleResponse);
    }

    function toggleItem(index) {
        saveItems(Memo.toggleItem(items, index));
    }

    function deleteItem(index) {
        saveItems(Memo.removeItem(items, index));
    }

    function addItem(text) {
        if (text.trim() === "")
            return false;
        saveItems(Memo.addItem(items, text));
        return true;
    }

    function openInBrowser() {
        if (!configured)
            return;
        Qt.openUrlExternally(Memo.webUrl(cfg.serverUrl, cfg.memoId));
    }
}
