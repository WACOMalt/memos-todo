pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtCore
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami

import "../code/memo.js" as Memo

PlasmoidItem {
    id: root

    readonly property var cfg: Plasmoid.configuration

    readonly property bool hasServer: cfg.serverUrl.trim() !== "" && cfg.authToken.trim() !== ""
    readonly property bool hasMemoId: cfg.memoId.trim() !== ""
    readonly property bool configured: hasServer && hasMemoId

    // What is missing from the settings, or "" when nothing is.
    readonly property string configureText:
        !hasServer ? i18n("Please configure Server URL, Token and Memo ID in settings.")
      : !hasMemoId ? i18n("Memo ID not set. Enter the ID of the memo to show in the settings.")
      : ""

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
        if (!hasServer)
            return i18n("Configure Settings");
        if (!hasMemoId)
            return i18n("Memo ID not set");
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
    toolTipSubText: !configured ? configureText
                  : hasError ? statusText
                  : !loaded ? i18n("Loading...")
                  : todoCount === 0 ? i18n("Empty Memo")
                  : i18np("%1 open task", "%1 open tasks", openCount)

    // On the desktop the widget shows the list itself, like the popup,
    // instead of the panel label.
    readonly property bool onDesktop: Plasmoid.formFactor === PlasmaCore.Types.Planar
                                      || Plasmoid.formFactor === PlasmaCore.Types.MediaCenter
    // A desktop style other than "theme" draws its own background, so the
    // theme background goes.
    readonly property bool customBackground: onDesktop && cfg.desktopStyle !== "theme"

    Plasmoid.backgroundHints: customBackground ? PlasmaCore.Types.NoBackground
                                               : PlasmaCore.Types.DefaultBackground

    preferredRepresentation: onDesktop ? fullRepresentation : compactRepresentation
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
        function onServerUrlChanged() { root.writeShared(); root.settingsChanged() }
        function onAuthTokenChanged() { root.writeShared(); root.settingsChanged() }
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

    Component.onCompleted: {
        exec.connectSource(prepareSharedCommand);
        fetchMemo();
    }

    // The server URL and the access token are the same for every Memos
    // ToDo widget, so they are kept in one file that all the widgets share.
    // Each widget keeps its own memo ID. The widget configuration holds a
    // copy of the two shared values, so the settings page shows them and
    // a change there goes into the file.
    readonly property string sharedDir:
        StandardPaths.writableLocation(StandardPaths.GenericConfigLocation).toString().replace("file://", "")
        + "/memos-todo"
    readonly property string sharedPath: sharedDir + "/server.conf"
    // The file holds the access token, so only the user may read it.
    // Qt keeps the permissions of an existing file when it writes to it.
    readonly property string prepareSharedCommand:
        "umask 077; mkdir -p '" + sharedDir + "' && touch '" + sharedPath + "'"
    property bool sharedReady: false
    // True while readShared copies the file into this widget, so that the
    // copy does not go back into the file one value at a time.
    property bool readingShared: false

    Settings {
        id: shared
        location: "file://" + root.sharedPath
        category: "Server"
    }

    P5Support.DataSource {
        id: exec
        engine: "executable"
        connectedSources: []
        onNewData: (sourceName, data) => {
            disconnectSource(sourceName);
            if (sourceName === root.prepareSharedCommand) {
                root.sharedReady = true;
                root.readShared();
            }
        }
    }

    // Another widget can change the shared values at any time.
    Timer {
        interval: 3000
        repeat: true
        running: root.sharedReady
        onTriggered: root.readShared()
    }

    // Copies the shared values into this widget. If the file has no values
    // yet, this widget gives it its own, for example from an earlier
    // version that kept them per widget.
    function readShared() {
        if (!sharedReady)
            return;
        shared.sync();
        const url = String(shared.value("serverUrl", ""));
        const token = String(shared.value("authToken", ""));
        if (url === "" && token === "") {
            if (cfg.authToken !== "")
                writeShared();
            return;
        }
        readingShared = true;
        if (url !== cfg.serverUrl)
            cfg.serverUrl = url;
        if (token !== cfg.authToken)
            cfg.authToken = token;
        readingShared = false;
    }

    function writeShared() {
        if (!sharedReady || readingShared)
            return;
        shared.setValue("serverUrl", cfg.serverUrl);
        shared.setValue("authToken", cfg.authToken);
        shared.sync();
    }

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
                handleError(statusMessage(xhr.status));
            } else {
                onSuccess(xhr.responseText);
            }
        };
        xhr.send(body);
    }

    // A message for an HTTP error status. The common ones say what to fix.
    function statusMessage(status) {
        if (status === 404)
            return i18n("Memo not found. Check the memo ID in the settings.");
        if (status === 401 || status === 403)
            return i18n("Access token rejected. Check the token in the settings.");
        return i18n("Error %1", status);
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
            statusText = configureText;
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
