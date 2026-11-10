import QtQuick
import QtQuick.Layouts
import Sylphrena.Config
import qs.components
import qs.components.controls
import qs.services

// A label + subtext with a spin box, for settings that live inside a card (no nested
// ConnectedRect). Used by the Nexus pages and by the settings component of extensions.
RowLayout {
    id: root

    property alias label: settingLabel.text
    property alias subtext: settingSub.text
    property alias value: spin.value
    property alias from: spin.from
    property alias to: spin.to
    property alias stepSize: spin.stepSize

    signal moved(value: real)

    // Same height with or without a subtext, so the rows line up evenly
    Layout.fillWidth: true
    Layout.preferredHeight: 52
    spacing: Tokens.spacing.medium

    ColumnLayout {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter
        spacing: 0

        StyledText {
            id: settingLabel

            Layout.fillWidth: true
            font: Tokens.font.body.small
            elide: Text.ElideRight
        }

        StyledText {
            id: settingSub

            Layout.fillWidth: true
            visible: text.length > 0
            color: Colours.palette.m3outline
            font: Tokens.font.label.small
            elide: Text.ElideRight
        }
    }

    StyledSpinBox {
        id: spin

        cLayer: 2
        onValueModified: root.moved(value)
    }
}
