import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami
import org.kde.kquickcontrols as KQuickControls
import org.kde.ksvg as KSvg

import "../code/styles.js" as Styles

// The settings of the desktop widget. They apply when the widget is on the
// desktop. In a panel the widget uses the settings of the General page.
KCM.SimpleKCM {
    id: page

    property string cfg_desktopStyle: "theme"
    property string cfg_desktopStyleDefault: "theme"
    property alias cfg_desktopBackgroundColor: backgroundButton.color
    property color cfg_desktopBackgroundColorDefault: "#fff59d"
    property alias cfg_desktopTextColor: textButton.color
    property color cfg_desktopTextColorDefault: "#3b3a1f"
    property alias cfg_desktopOpacity: opacitySlider.value
    property int cfg_desktopOpacityDefault: 100
    property alias cfg_desktopFontSize: fontSpin.value
    property int cfg_desktopFontSizeDefault: 11
    property alias cfg_desktopShowControls: showControlsBox.checked
    property bool cfg_desktopShowControlsDefault: true

    readonly property var styleNames: ({
        "theme": i18n("Plasma theme"),
        "translucent": i18n("Translucent"),
        "translucent-light": i18n("Translucent light"),
        "yellow": i18n("Yellow"),
        "white": i18n("White"),
        "black": i18n("Black"),
        "red": i18n("Red"),
        "orange": i18n("Orange"),
        "green": i18n("Green"),
        "blue": i18n("Blue"),
        "pink": i18n("Pink"),
        "custom": i18n("Custom colors"),
    })

    readonly property var previewColors: Styles.colors(cfg_desktopStyle, backgroundButton.color, textButton.color)
    readonly property string previewNote:
        previewColors ? Styles.noteElement(previewColors.svg, (id) => notesSvg.hasElement(id)) : ""

    ColumnLayout {
        width: page.width
        spacing: Kirigami.Units.largeSpacing

        Kirigami.InlineMessage {
            Layout.fillWidth: true
            Layout.maximumWidth: page.width - Kirigami.Units.gridUnit
            visible: true
            type: Kirigami.MessageType.Information
            text: i18n("These settings apply when the widget is on the desktop. In a panel, the widget uses the General settings.")
        }

        Kirigami.FormLayout {
            Layout.fillWidth: true

            QQC2.ComboBox {
                id: styleCombo
                Kirigami.FormData.label: i18n("Colors:")
                model: Styles.IDS.map(id => ({ value: id, text: page.styleNames[id] }))
                textRole: "text"
                valueRole: "value"
                currentIndex: Math.max(0, Styles.IDS.indexOf(page.cfg_desktopStyle))
                onActivated: {
                    // Custom colors start from the colors of the preset
                    // that was selected.
                    const preset = Styles.PRESETS[page.cfg_desktopStyle];
                    if (currentValue === "custom" && preset) {
                        backgroundButton.color = preset.background;
                        textButton.color = preset.text;
                    }
                    page.cfg_desktopStyle = currentValue;
                }
            }

            KQuickControls.ColorButton {
                id: backgroundButton
                Kirigami.FormData.label: i18n("Background color:")
                enabled: page.cfg_desktopStyle === "custom"
                dialogTitle: i18n("Background color")
            }

            KQuickControls.ColorButton {
                id: textButton
                Kirigami.FormData.label: i18n("Text color:")
                enabled: page.cfg_desktopStyle === "custom"
                dialogTitle: i18n("Text color")
            }

            RowLayout {
                Kirigami.FormData.label: i18n("Background opacity:")
                enabled: page.cfg_desktopStyle !== "theme"

                QQC2.Slider {
                    id: opacitySlider
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 10
                    from: 10
                    to: 100
                    stepSize: 5
                    snapMode: QQC2.Slider.SnapAlways
                }
                QQC2.Label {
                    text: i18n("%1 %", opacitySlider.value)
                }
            }

            Item { Kirigami.FormData.isSection: true }

            QQC2.SpinBox {
                id: fontSpin
                Kirigami.FormData.label: i18n("Font size:")
                from: 8
                to: 48
                stepSize: 1
                editable: true
                textFromValue: (value) => i18n("%1 pt", value)
                valueFromText: (text) => parseInt(text) || 11
            }

            QQC2.CheckBox {
                id: showControlsBox
                Kirigami.FormData.label: i18n("Show:")
                text: i18n("New task field and Open in Browser button")
            }

            Item { Kirigami.FormData.isSection: true }

            // A sample of the widget in the selected colors.
            Rectangle {
                Kirigami.FormData.label: i18n("Preview:")
                implicitWidth: Kirigami.Units.gridUnit * 14
                implicitHeight: previewColumn.implicitHeight + Kirigami.Units.largeSpacing * 2
                radius: Kirigami.Units.cornerRadius
                color: "transparent"
                border.color: Kirigami.ColorUtils.linearInterpolation(Kirigami.Theme.backgroundColor, Kirigami.Theme.textColor, 0.2)
                border.width: page.previewColors ? 0 : 1

                KSvg.Svg {
                    id: notesSvg
                    imagePath: "widgets/notes"
                }

                // The note image of a preset, as on the desktop.
                KSvg.SvgItem {
                    anchors.fill: parent
                    visible: page.previewNote !== ""
                    svg: notesSvg
                    elementId: page.previewNote
                    opacity: opacitySlider.value / 100
                }

                // The plain background of the custom colors.
                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    visible: page.previewColors !== null && page.previewColors.svg === ""
                    color: page.previewColors ? page.previewColors.background : "transparent"
                    opacity: opacitySlider.value / 100
                }

                ColumnLayout {
                    id: previewColumn
                    anchors.fill: parent
                    anchors.margins: Kirigami.Units.largeSpacing + (page.previewNote !== "" ? Math.round(parent.width * 0.04) : 0)
                    spacing: Kirigami.Units.smallSpacing

                    Repeater {
                        model: ["☑ " + i18n("A completed task"), "☐ " + i18n("An open task")]
                        delegate: QQC2.Label {
                            required property string modelData
                            required property int index
                            text: modelData
                            color: page.previewColors ? page.previewColors.text : Kirigami.Theme.textColor
                            font.pointSize: fontSpin.value
                            font.strikeout: index === 0
                            opacity: index === 0 ? 0.6 : 1
                        }
                    }
                }
            }
        }
    }
}
