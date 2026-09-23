pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

// The panel label. It shows one memo line at a time and moves to the next
// line after the text cycle interval: the old line slides up and fades
// out, then the new line slides up from below and fades in.
MouseArea {
    id: compact

    // The PlasmoidItem of main.qml.
    required property var app
    readonly property var cfg: Plasmoid.configuration
    readonly property bool vertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical
    readonly property bool fixedWidth: cfg.setPanelWidth && !vertical
    readonly property int sidePadding: Kirigami.Units.smallSpacing * 2
    // The distance of the slide, as in the Cinnamon applet.
    readonly property int slideDistance: 20

    Layout.minimumWidth: vertical ? -1 : (fixedWidth ? cfg.panelWidth : Kirigami.Units.gridUnit)
    Layout.preferredWidth: vertical ? -1 : (fixedWidth ? cfg.panelWidth : label.implicitWidth + sidePadding * 2)
    Layout.maximumWidth: fixedWidth ? cfg.panelWidth : -1
    Layout.preferredHeight: vertical ? label.implicitHeight + sidePadding : -1

    clip: true
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton

    property bool wasExpanded: false
    onPressed: wasExpanded = compact.app.expanded
    onClicked: compact.app.expanded = !wasExpanded

    PlasmaComponents.Label {
        id: label

        anchors.verticalCenter: parent.verticalCenter
        x: compact.sidePadding
        width: compact.fixedWidth || compact.vertical ? compact.width - compact.sidePadding * 2 : implicitWidth

        text: compact.app.panelText
        font.pointSize: compact.cfg.panelFontSize
        elide: compact.fixedWidth || compact.vertical ? Text.ElideRight : Text.ElideNone
        wrapMode: Text.NoWrap
        maximumLineCount: 1
        textFormat: Text.PlainText

        transform: Translate { id: shift }
    }

    Timer {
        id: cycleTimer
        interval: Math.max(1, compact.cfg.scrollInterval) * 1000
        repeat: true
        running: compact.app.panelLines.length > 1
        onTriggered: {
            if (compact.cfg.transitionDuration > 0)
                slide.restart();
            else
                compact.app.nextLine();
        }
    }

    SequentialAnimation {
        id: slide

        readonly property int duration: compact.cfg.transitionDuration

        ParallelAnimation {
            NumberAnimation {
                target: label; property: "opacity"; to: 0
                duration: slide.duration; easing.type: Easing.OutQuad
            }
            NumberAnimation {
                target: shift; property: "y"; to: -compact.slideDistance
                duration: slide.duration; easing.type: Easing.OutQuad
            }
        }
        ScriptAction {
            script: {
                compact.app.nextLine();
                shift.y = compact.slideDistance;
            }
        }
        ParallelAnimation {
            NumberAnimation {
                target: label; property: "opacity"; to: 1
                duration: slide.duration; easing.type: Easing.InQuad
            }
            NumberAnimation {
                target: shift; property: "y"; to: 0
                duration: slide.duration; easing.type: Easing.InQuad
            }
        }
    }

    // A stopped slide must not leave the label invisible or out of place.
    Connections {
        target: cycleTimer
        function onRunningChanged() {
            if (!cycleTimer.running) {
                slide.stop();
                label.opacity = 1;
                shift.y = 0;
            }
        }
    }
}
