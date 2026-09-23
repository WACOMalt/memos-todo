pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.extras as PlasmaExtras
import org.kde.kirigami as Kirigami

// The popup. From top to bottom: a status line, the memo items, a
// separator, the field for a new task, and the "Open in Browser" button.
// This is the layout of the Cinnamon applet popup.
PlasmaExtras.Representation {
    id: full

    // The PlasmoidItem of main.qml.
    required property var app
    readonly property var cfg: Plasmoid.configuration
    readonly property real fontSize: cfg.popupFontSize
    // The maximum height of the item list before it scrolls, as in the
    // Cinnamon applet.
    readonly property int maxListHeight: 450

    Layout.minimumWidth: cfg.popupWidth
    Layout.preferredWidth: cfg.popupWidth
    Layout.maximumWidth: cfg.popupWidth
    // The popup opens at the height of its content. When it is made
    // taller, the item list takes the extra height.
    Layout.minimumHeight: Kirigami.Units.gridUnit * 8
    Layout.preferredHeight: content.implicitHeight + Kirigami.Units.largeSpacing * 2

    collapseMarginsHint: true

    // Give the new task field the focus each time the popup opens.
    Connections {
        target: full.app
        function onExpandedChanged() {
            if (full.app.expanded) {
                newTaskField.forceActiveFocus();
            }
        }
    }

    ColumnLayout {
        id: content

        anchors.fill: parent
        anchors.margins: Kirigami.Units.largeSpacing
        spacing: Kirigami.Units.smallSpacing

        PlasmaComponents.ScrollView {
            id: scroll

            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredHeight: Math.min(itemColumn.implicitHeight, full.maxListHeight)
            QQC2.ScrollBar.horizontal.policy: QQC2.ScrollBar.AlwaysOff
            contentWidth: availableWidth

            ColumnLayout {
                id: itemColumn

                width: scroll.availableWidth
                spacing: Kirigami.Units.smallSpacing

                PlasmaComponents.Label {
                    Layout.fillWidth: true
                    Layout.margins: Kirigami.Units.smallSpacing
                    visible: full.app.statusText !== ""
                    text: full.app.statusText
                    font.pointSize: full.fontSize
                    color: full.app.hasError ? Kirigami.Theme.negativeTextColor : Kirigami.Theme.textColor
                    wrapMode: Text.Wrap
                    textFormat: Text.PlainText
                }

                PlasmaComponents.Button {
                    visible: !full.app.configured
                    text: i18n("Configure…")
                    icon.name: "configure"
                    font.pointSize: full.fontSize
                    onClicked: Plasmoid.internalAction("configure").trigger()
                }

                Repeater {
                    model: full.app.items

                    delegate: Loader {
                        id: itemLoader

                        required property var modelData
                        required property int index

                        readonly property bool hidden: modelData.type === "todo"
                                                       && modelData.checked
                                                       && !full.cfg.showCompletedPopup

                        Layout.fillWidth: true
                        visible: !hidden
                        active: !hidden
                        sourceComponent: modelData.type === "todo" ? todoRow : textBlock

                        Component {
                            id: textBlock

                            PlasmaComponents.Label {
                                padding: Kirigami.Units.smallSpacing
                                text: itemLoader.modelData.lines.join("\n")
                                font.pointSize: full.fontSize
                                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                                textFormat: Text.PlainText
                            }
                        }

                        Component {
                            id: todoRow

                            RowLayout {
                                spacing: Kirigami.Units.smallSpacing

                                PlasmaComponents.ItemDelegate {
                                    id: todoButton

                                    Layout.fillWidth: true
                                    Accessible.role: Accessible.CheckBox
                                    Accessible.checked: itemLoader.modelData.checked
                                    Accessible.name: itemLoader.modelData.lines[0].substring(2)
                                    onClicked: full.app.toggleItem(itemLoader.index)

                                    contentItem: PlasmaComponents.Label {
                                        text: itemLoader.modelData.lines.join("\n")
                                        font.pointSize: full.fontSize
                                        font.strikeout: itemLoader.modelData.checked
                                        opacity: itemLoader.modelData.checked ? 0.6 : 1
                                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                                        textFormat: Text.PlainText
                                    }
                                }

                                PlasmaComponents.ToolButton {
                                    id: deleteButton

                                    Layout.alignment: Qt.AlignVCenter
                                    Accessible.name: i18n("Delete task")
                                    display: QQC2.AbstractButton.IconOnly
                                    text: i18n("Delete task")
                                    onClicked: full.app.deleteItem(itemLoader.index)

                                    contentItem: Kirigami.Icon {
                                        implicitWidth: Kirigami.Units.iconSizes.small
                                        implicitHeight: Kirigami.Units.iconSizes.small
                                        source: "edit-delete-symbolic"
                                        isMask: true
                                        color: Kirigami.Theme.negativeTextColor
                                        opacity: deleteButton.hovered || deleteButton.activeFocus ? 1 : 0.7
                                    }

                                    PlasmaComponents.ToolTip.text: text
                                    PlasmaComponents.ToolTip.visible: hovered
                                    PlasmaComponents.ToolTip.delay: Kirigami.Units.toolTipDelay
                                }
                            }
                        }
                    }
                }
            }
        }

        Kirigami.Separator {
            Layout.fillWidth: true
            Layout.topMargin: Kirigami.Units.smallSpacing
            Layout.bottomMargin: Kirigami.Units.smallSpacing
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            PlasmaComponents.TextField {
                id: newTaskField

                Layout.fillWidth: true
                placeholderText: i18n("New task...")
                font.pointSize: full.fontSize
                enabled: full.app.configured
                onAccepted: full.saveNewTask()
            }

            PlasmaComponents.Button {
                text: " + "
                font.pointSize: full.fontSize
                enabled: full.app.configured && newTaskField.text.trim() !== ""
                Accessible.name: i18n("Add task")
                onClicked: full.saveNewTask()

                PlasmaComponents.ToolTip.text: i18n("Add task")
                PlasmaComponents.ToolTip.visible: hovered
                PlasmaComponents.ToolTip.delay: Kirigami.Units.toolTipDelay
            }
        }

        PlasmaComponents.Button {
            Layout.fillWidth: true
            text: i18n("Open in Browser")
            font.pointSize: full.fontSize
            enabled: full.app.configured
            onClicked: full.app.openInBrowser()
        }
    }

    function saveNewTask() {
        if (app.addItem(newTaskField.text)) {
            newTaskField.clear();
            // Show the new task, which is at the end of the list.
            Qt.callLater(() => {
                const flick = scroll.contentItem;
                flick.contentY = Math.max(0, flick.contentHeight - flick.height);
            });
        }
    }
}
