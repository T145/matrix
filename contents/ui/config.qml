import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.20 as Kirigami

ColumnLayout {
    id: configRoot

    // cfg_ prefixed properties auto-bind to wallpaper configuration keys
    property alias cfg_fontSize:    fontSizeSpinBox.value
    property alias cfg_speed:       speedSpinBox.value
    property alias cfg_fadeRate:    fadeRateSlider.value
    property alias cfg_mirrorChars: mirrorCheck.checked
    property alias cfg_glowEnabled: glowCheck.checked
    property alias cfg_glowRadius:  glowRadiusSpinBox.value
    property alias cfg_charSet:     charSetCombo.currentIndex

    // Colors need manual handling (alias to text, bound in both directions)
    property string cfg_matrixColor
    property string cfg_headColor
    property string cfg_fontFamily

    Kirigami.FormLayout {
        Layout.fillWidth: true

        // --- Character Set ---------------------------------------------------
        Kirigami.Separator {
            Kirigami.FormData.label: "Characters"
            Kirigami.FormData.isSection: true
        }

        QQC.ComboBox {
            id: charSetCombo
            Kirigami.FormData.label: "Character Set:"
            model: [
                "Lore-accurate (katakana + digits + symbols)",
                "Katakana only",
                "Extended (katakana + Latin + digits + symbols)"
            ]
        }

        QQC.CheckBox {
            id: mirrorCheck
            Kirigami.FormData.label: "Mirror Characters:"
            text: "Flip katakana horizontally (lore-accurate)"
        }

        // --- Appearance ------------------------------------------------------
        Kirigami.Separator {
            Kirigami.FormData.label: "Appearance"
            Kirigami.FormData.isSection: true
        }

        QQC.SpinBox {
            id: fontSizeSpinBox
            Kirigami.FormData.label: "Font Size:"
            from: 8
            to: 48
            stepSize: 1
        }

        QQC.TextField {
            id: fontFamilyField
            Kirigami.FormData.label: "Font Family:"
            text: configRoot.cfg_fontFamily
            onTextChanged: configRoot.cfg_fontFamily = text
            placeholderText: "Noto Sans Mono CJK JP"
        }

        QQC.TextField {
            id: matrixColorField
            Kirigami.FormData.label: "Trail Color:"
            text: configRoot.cfg_matrixColor
            onTextChanged: configRoot.cfg_matrixColor = text
            placeholderText: "#00ff41"

            Rectangle {
                anchors.right: parent.right
                anchors.rightMargin: 4
                anchors.verticalCenter: parent.verticalCenter
                width: 20; height: 20; radius: 3
                color: parent.text
                border.color: Kirigami.Theme.textColor
                border.width: 1
            }
        }

        QQC.TextField {
            id: headColorField
            Kirigami.FormData.label: "Head Color:"
            text: configRoot.cfg_headColor
            onTextChanged: configRoot.cfg_headColor = text
            placeholderText: "#ccffcc"

            Rectangle {
                anchors.right: parent.right
                anchors.rightMargin: 4
                anchors.verticalCenter: parent.verticalCenter
                width: 20; height: 20; radius: 3
                color: parent.text
                border.color: Kirigami.Theme.textColor
                border.width: 1
            }
        }

        // --- Animation -------------------------------------------------------
        Kirigami.Separator {
            Kirigami.FormData.label: "Animation"
            Kirigami.FormData.isSection: true
        }

        QQC.SpinBox {
            id: speedSpinBox
            Kirigami.FormData.label: "Speed (FPS):"
            from: 5
            to: 60
            stepSize: 5
        }

        RowLayout {
            Kirigami.FormData.label: "Fade Rate:"
            spacing: Kirigami.Units.smallSpacing

            QQC.Slider {
                id: fadeRateSlider
                Layout.fillWidth: true
                from: 0.01
                to: 0.20
                stepSize: 0.01
            }

            QQC.Label {
                text: fadeRateSlider.value.toFixed(2)
                Layout.minimumWidth: Kirigami.Units.gridUnit * 2
            }
        }

        // --- Glow ------------------------------------------------------------
        Kirigami.Separator {
            Kirigami.FormData.label: "Effects"
            Kirigami.FormData.isSection: true
        }

        QQC.CheckBox {
            id: glowCheck
            Kirigami.FormData.label: "Glow:"
            text: "Enable glow on leading character"
        }

        QQC.SpinBox {
            id: glowRadiusSpinBox
            Kirigami.FormData.label: "Glow Radius:"
            from: 2
            to: 24
            stepSize: 1
            enabled: glowCheck.checked
        }
    }
}
