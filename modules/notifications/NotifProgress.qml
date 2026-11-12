import QtQuick
import QtQuick.Layouts
import Sylphrena.Config
import qs.components
import qs.components.controls
import qs.services

// The progress of a notification: a thin wavy bar (Material 3 Expressive, like the media player's) with optional
// texts at its ends (notif.progressFrom / progressTo: "1497 ml" … "2600 ml").
RowLayout {
    id: root

    required property var notif
    property bool still: false

    spacing: Tokens.spacing.small

    StyledText {
        visible: text.length > 0
        text: root.notif?.progressFrom ?? ""
        color: Colours.palette.m3onSurfaceVariant
        font: Tokens.font.label.small
    }

    StyledProgressBar {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter
        implicitHeight: 3
        value: Math.max(0, root.notif?.progress ?? 0)
        wavy: true
        wavePaused: root.still
        waveAmplitude: 0.6
    }

    StyledText {
        visible: text.length > 0
        text: root.notif?.progressTo ?? ""
        color: Colours.palette.m3onSurfaceVariant
        font: Tokens.font.label.small
    }
}
