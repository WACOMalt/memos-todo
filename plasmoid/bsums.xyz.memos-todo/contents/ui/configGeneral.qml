import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami

// The settings of the Cinnamon applet, in the same order, with the same
// defaults and ranges.
KCM.SimpleKCM {
    id: page

    property alias cfg_serverUrl: serverUrlField.text
    property string cfg_serverUrlDefault: "https://memos.example.com"
    property alias cfg_authToken: authTokenField.text
    property string cfg_authTokenDefault: ""
    property alias cfg_memoId: memoIdField.text
    property string cfg_memoIdDefault: ""
    property alias cfg_refreshInterval: refreshSpin.value
    property int cfg_refreshIntervalDefault: 10
    property alias cfg_popupFontSize: popupFontSpin.value
    property int cfg_popupFontSizeDefault: 11
    property alias cfg_panelFontSize: panelFontSpin.value
    property int cfg_panelFontSizeDefault: 10
    property alias cfg_popupWidth: popupWidthSpin.value
    property int cfg_popupWidthDefault: 300
    property alias cfg_scrollInterval: scrollSpin.value
    property int cfg_scrollIntervalDefault: 5
    property alias cfg_setPanelWidth: setPanelWidthBox.checked
    property bool cfg_setPanelWidthDefault: false
    property alias cfg_panelWidth: panelWidthSpin.value
    property int cfg_panelWidthDefault: 150
    property alias cfg_showCompletedPanel: showCompletedPanelBox.checked
    property bool cfg_showCompletedPanelDefault: true
    property alias cfg_showCompletedPopup: showCompletedPopupBox.checked
    property bool cfg_showCompletedPopupDefault: true
    property alias cfg_transitionDuration: transitionSpin.value
    property int cfg_transitionDurationDefault: 300

    Kirigami.FormLayout {
        // Connection

        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Connection")
        }

        // Credit to the project this widget depends on.
        QQC2.Label {
            Layout.fillWidth: true
            Layout.maximumWidth: Kirigami.Units.gridUnit * 18
            wrapMode: Text.Wrap
            textFormat: Text.StyledText
            linkColor: Kirigami.Theme.linkColor
            text: i18n("Memos ToDo needs a server running UseMemos, the open-source, self-hosted note service. Find out more at %1.",
                       "<a href=\"https://usememos.com\">usememos.com</a>")
            onLinkActivated: (link) => Qt.openUrlExternally(link)

            HoverHandler {
                cursorShape: parent.hoveredLink !== "" ? Qt.PointingHandCursor : Qt.ArrowCursor
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Server URL:")
            Layout.fillWidth: true

            QQC2.TextField {
                id: serverUrlField
                Layout.fillWidth: true
                Layout.minimumWidth: Kirigami.Units.gridUnit * 16
                placeholderText: "https://memos.example.com"
                inputMethodHints: Qt.ImhUrlCharactersOnly | Qt.ImhNoAutoUppercase
            }
            Kirigami.ContextualHelpButton {
                toolTipText: i18n("The base URL of your Memos server")
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Access token:")
            Layout.fillWidth: true

            Kirigami.PasswordField {
                id: authTokenField
                Layout.fillWidth: true
                Layout.minimumWidth: Kirigami.Units.gridUnit * 16
            }
            Kirigami.ContextualHelpButton {
                toolTipText: i18n("Your API Access Token (Bearer token not including 'Bearer ' prefix)")
            }
        }

        QQC2.Label {
            Layout.fillWidth: true
            Layout.maximumWidth: Kirigami.Units.gridUnit * 18
            wrapMode: Text.Wrap
            font: Kirigami.Theme.smallFont
            opacity: 0.7
            text: i18n("All Memos ToDo widgets share the server URL and the access token. Each widget has its own memo ID.")
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Memo ID:")
            Layout.fillWidth: true

            QQC2.TextField {
                id: memoIdField
                Layout.fillWidth: true
                Layout.minimumWidth: Kirigami.Units.gridUnit * 16
                inputMethodHints: Qt.ImhNoAutoUppercase
            }
            Kirigami.ContextualHelpButton {
                toolTipText: i18n("The ID of the memo you want to show (found in the memo URL or details)")
            }
        }

        QQC2.SpinBox {
            id: refreshSpin
            Kirigami.FormData.label: i18n("Refresh interval:")
            from: 1
            to: 1440
            stepSize: 1
            editable: true
            textFromValue: (value) => i18np("%1 minute", "%1 minutes", value)
            valueFromText: (text) => parseInt(text) || 1
        }

        // Popup

        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Popup")
        }

        QQC2.SpinBox {
            id: popupFontSpin
            Kirigami.FormData.label: i18n("Popup font size:")
            from: 8
            to: 32
            stepSize: 1
            editable: true
            textFromValue: (value) => i18n("%1 pt", value)
            valueFromText: (text) => parseInt(text) || 11
        }

        QQC2.SpinBox {
            id: popupWidthSpin
            Kirigami.FormData.label: i18n("Popup width:")
            from: 100
            to: 1000
            stepSize: 10
            editable: true
            textFromValue: (value) => i18n("%1 px", value)
            valueFromText: (text) => parseInt(text) || 300
        }

        QQC2.CheckBox {
            id: showCompletedPopupBox
            text: i18n("Show completed tasks in popup")
        }

        // Panel

        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Panel")
        }

        QQC2.SpinBox {
            id: panelFontSpin
            Kirigami.FormData.label: i18n("Panel font size:")
            from: 6
            to: 24
            stepSize: 1
            editable: true
            textFromValue: (value) => i18n("%1 pt", value)
            valueFromText: (text) => parseInt(text) || 10
        }

        QQC2.CheckBox {
            id: setPanelWidthBox
            Kirigami.FormData.label: i18n("Panel width:")
            text: i18n("Use a fixed width")
        }

        QQC2.SpinBox {
            id: panelWidthSpin
            enabled: setPanelWidthBox.checked
            from: 20
            to: 1000
            stepSize: 5
            editable: true
            textFromValue: (value) => i18n("%1 px", value)
            valueFromText: (text) => parseInt(text) || 150
        }

        QQC2.CheckBox {
            id: showCompletedPanelBox
            text: i18n("Show completed tasks in panel")
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Text cycle interval:")

            QQC2.SpinBox {
                id: scrollSpin
                from: 1
                to: 60
                stepSize: 1
                editable: true
                textFromValue: (value) => i18np("%1 second", "%1 seconds", value)
                valueFromText: (text) => parseInt(text) || 5
            }
            Kirigami.ContextualHelpButton {
                toolTipText: i18n("Time to show each line before switching to the next")
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Panel slide duration:")

            QQC2.SpinBox {
                id: transitionSpin
                from: 0
                to: 2000
                stepSize: 50
                editable: true
                textFromValue: (value) => i18n("%1 ms", value)
                valueFromText: (text) => { const n = parseInt(text); return isNaN(n) ? 300 : n; }
            }
            Kirigami.ContextualHelpButton {
                toolTipText: i18n("0 ms turns the slide animation off.")
            }
        }
    }
}
