pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.extras as PlasmaExtras
import org.kde.kirigami as Kirigami
import org.kde.ksvg as KSvg

import "../code/styles.js" as Styles

// The popup, and the desktop widget. From top to bottom: a status line, the memo items, a
// separator, the field for a new task, and the "Open in Browser" button.
// This is the layout of the Cinnamon applet popup. On the desktop the same
// view fills the widget, with the colors of the "Desktop Widget" settings.
PlasmaExtras.Representation {
    id: full

    // The PlasmoidItem of main.qml.
    required property var app
    readonly property var cfg: Plasmoid.configuration
    readonly property bool onDesktop: app.onDesktop
    readonly property real fontSize: onDesktop ? cfg.desktopFontSize : cfg.popupFontSize
    readonly property bool showControls: !onDesktop || cfg.desktopShowControls
    // The colors of the desktop style, or null for the theme colors.
    readonly property var style: app.customBackground
                                 ? Styles.colors(cfg.desktopStyle, cfg.desktopBackgroundColor, cfg.desktopTextColor)
                                 : null
    // The maximum height of the item list before it scrolls, as in the
    // Cinnamon applet. On the desktop the list takes the widget height.
    readonly property int maxListHeight: 450

    // The popup has the width from the settings. The desktop widget has
    // the width that the user gives it, and starts at the popup width.
    Layout.minimumWidth: onDesktop ? Kirigami.Units.gridUnit * 8 : cfg.popupWidth
    Layout.preferredWidth: cfg.popupWidth
    Layout.maximumWidth: onDesktop ? -1 : cfg.popupWidth
    // The popup opens at the height of its content. When it is made
    // taller, the item list takes the extra height.
    Layout.minimumHeight: Kirigami.Units.gridUnit * 8
    Layout.preferredHeight: content.implicitHeight + Kirigami.Units.largeSpacing * 2

    collapseMarginsHint: true

    // The labels take the text color of the style.
    readonly property color textColor: style ? style.text : Kirigami.Theme.textColor
    // The theme colors outside the widget. The content below takes these,
    // or the style colors, so that fields and buttons suit the background.
    readonly property color themeBackgroundColor: Kirigami.Theme.backgroundColor
    readonly property color themeTextColor: Kirigami.Theme.textColor

    // A widget at an angle on the desktop is drawn into a layer, which is
    // then turned without smoothing a hard edge. So the background needs a
    // soft edge of its own, like the note image of the sticky note widget.

    KSvg.Svg {
        id: notesSvg
        imagePath: "widgets/notes"
    }

    // The note image of the Plasma theme, for the preset styles. It has a
    // transparent margin of about 4 % on each side.
    readonly property string noteElement:
        style ? Styles.noteElement(style.svg, (id) => notesSvg.hasElement(id)) : ""
    readonly property real noteMarginX: noteElement !== "" ? Math.round(width * 0.04) : 0
    readonly property real noteMarginY: noteElement !== "" ? Math.round(height * 0.04) : 0

    KSvg.SvgItem {
        anchors.fill: parent
        visible: full.noteElement !== ""
        svg: notesSvg
        elementId: full.noteElement
        opacity: full.cfg.desktopOpacity / 100
    }

    // The custom colors have no note image, so their background is painted
    // as an image too, with a soft shadow like the note image has. When the
    // widget is turned, Plasma does not smooth its edges; the shadow makes
    // the edge a soft change over a few pixels instead of a hard step.
    readonly property color customBackground: style && style.svg === "" ? style.background : "transparent"
    readonly property int customMargin: style && style.svg === "" ? 8 : 0

    Canvas {
        id: customCanvas

        anchors.fill: parent
        visible: full.style !== null && full.style.svg === ""
        opacity: full.cfg.desktopOpacity / 100

        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onVisibleChanged: requestPaint()

        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            if (!visible)
                return;
            // Room for the shadow around the background, as the note image
            // has.
            const m = full.customMargin;
            const r = Kirigami.Units.cornerRadius;
            ctx.shadowColor = Qt.rgba(0, 0, 0, 0.35);
            ctx.shadowBlur = m - 2;
            ctx.shadowOffsetY = 1;
            ctx.fillStyle = full.customBackground;
            ctx.beginPath();
            ctx.roundedRect(m, m, width - 2 * m, height - 2 * m, r, r);
            ctx.fill();
        }

        Connections {
            target: full
            function onCustomBackgroundChanged() { customCanvas.requestPaint() }
        }
    }

    // Give the new task field the focus each time the popup opens.
    Connections {
        target: full.app
        function onExpandedChanged() {
            if (full.app.expanded && !full.onDesktop && controls.item) {
                controls.item.field.forceActiveFocus();
            }
        }
    }

    ColumnLayout {
        id: content

        anchors.fill: parent
        anchors.leftMargin: Kirigami.Units.largeSpacing + full.noteMarginX + full.customMargin
        anchors.rightMargin: Kirigami.Units.largeSpacing + full.noteMarginX + full.customMargin
        anchors.topMargin: Kirigami.Units.largeSpacing + full.noteMarginY + full.customMargin
        anchors.bottomMargin: Kirigami.Units.largeSpacing + full.noteMarginY + full.customMargin
        spacing: Kirigami.Units.smallSpacing

        Kirigami.Theme.textColor: full.style ? full.style.text : full.themeTextColor
        Kirigami.Theme.backgroundColor: full.style ? full.style.background : full.themeBackgroundColor

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
                    color: full.app.hasError ? Kirigami.Theme.negativeTextColor : full.textColor
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
                                color: full.textColor
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
                                    // The padding of the Cinnamon applet rows.
                                    topPadding: Kirigami.Units.smallSpacing * 1.5
                                    bottomPadding: Kirigami.Units.smallSpacing * 1.5
                                    leftPadding: Kirigami.Units.smallSpacing * 2
                                    rightPadding: Kirigami.Units.smallSpacing * 2

                                    // The hover look of the Cinnamon applet: a light
                                    // box with a rounded border.
                                    background: Rectangle {
                                        radius: Kirigami.Units.cornerRadius
                                        color: todoButton.down ? full.tint(0.14)
                                             : todoButton.hovered ? full.tint(0.08)
                                             : "transparent"
                                        border.color: todoButton.hovered || todoButton.visualFocus
                                                      ? full.tint(0.2) : "transparent"
                                    }

                                    contentItem: PlasmaComponents.Label {
                                        text: itemLoader.modelData.lines.join("\n")
                                        color: full.textColor
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

        // The Plasma theme draws the field and the buttons from its own
        // graphics, which do not take other colors. A colored style draws
        // them in its own colors instead.
        Loader {
            id: controls

            Layout.fillWidth: true
            visible: full.showControls
            active: full.showControls
            sourceComponent: full.style ? styledControls : themeControls
        }
    }

    Component {
        id: themeControls

        ColumnLayout {
            readonly property Item field: newTaskField

            spacing: Kirigami.Units.smallSpacing

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
                    onAccepted: full.saveNewTask(newTaskField)
                }

                PlasmaComponents.Button {
                    text: " + "
                    font.pointSize: full.fontSize
                    enabled: full.app.configured && newTaskField.text.trim() !== ""
                    Accessible.name: i18n("Add task")
                    onClicked: full.saveNewTask(newTaskField)

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
    }

    Component {
        id: styledControls

        ColumnLayout {
            readonly property Item field: styledField

            spacing: Kirigami.Units.smallSpacing

            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: Kirigami.Units.smallSpacing
                Layout.bottomMargin: Kirigami.Units.smallSpacing
                implicitHeight: 1
                color: full.tint(0.25)
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                QQC2.TextField {
                    id: styledField

                    Layout.fillWidth: true
                    placeholderText: i18n("New task...")
                    placeholderTextColor: full.tint(0.55)
                    color: full.textColor
                    selectionColor: full.tint(0.3)
                    selectedTextColor: full.textColor
                    font.pointSize: full.fontSize
                    enabled: full.app.configured
                    onAccepted: full.saveNewTask(styledField)

                    background: Rectangle {
                        radius: Kirigami.Units.cornerRadius
                        color: full.tint(0.08)
                        border.color: full.tint(styledField.activeFocus ? 0.6 : 0.25)
                    }
                }

                StyledButton {
                    id: addButton
                    text: " + "
                    enabled: full.app.configured && styledField.text.trim() !== ""
                    Accessible.name: i18n("Add task")
                    onClicked: full.saveNewTask(styledField)

                    QQC2.ToolTip.text: i18n("Add task")
                    QQC2.ToolTip.visible: hovered
                    QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
                }
            }

            StyledButton {
                Layout.fillWidth: true
                text: i18n("Open in Browser")
                enabled: full.app.configured
                onClicked: full.app.openInBrowser()
            }
        }
    }

    // A button in the colors of the style, after the bottom buttons of the
    // Cinnamon applet.
    component StyledButton: QQC2.Button {
        id: styledButton

        font.pointSize: full.fontSize
        opacity: enabled ? 1 : 0.5
        leftPadding: Kirigami.Units.largeSpacing
        rightPadding: Kirigami.Units.largeSpacing
        topPadding: Kirigami.Units.smallSpacing
        bottomPadding: Kirigami.Units.smallSpacing

        contentItem: QQC2.Label {
            text: styledButton.text
            font: styledButton.font
            color: full.textColor
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
        background: Rectangle {
            implicitHeight: Kirigami.Units.gridUnit * 1.6
            radius: Kirigami.Units.cornerRadius
            color: full.tint(styledButton.down ? 0.2 : styledButton.hovered ? 0.14 : 0.07)
            border.color: full.tint(styledButton.hovered || styledButton.activeFocus ? 0.35 : 0.15)
        }
    }

    // The text color of the view with the opacity a.
    function tint(a) {
        return Qt.rgba(textColor.r, textColor.g, textColor.b, a);
    }

    function saveNewTask(field) {
        if (app.addItem(field.text)) {
            field.clear();
            // Show the new task, which is at the end of the list.
            Qt.callLater(() => {
                const flick = scroll.contentItem;
                flick.contentY = Math.max(0, flick.contentHeight - flick.height);
            });
        }
    }
}
