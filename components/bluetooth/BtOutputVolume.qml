pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Sylphrena.Config
import Sylphrena.I18n
import qs.components
import qs.components.controls
import qs.services

RowLayout {
    id: vol

    required property var sink
    // The popout hides this for the active output (it would duplicate the system volume);
    // the Nexus page shows it always.
    property bool alwaysVisible
    readonly property bool muted: !!sink?.audio?.muted

    // Only for a headset that is not the active output: for the active one this is the system volume
    visible: !!sink?.audio && (alwaysVisible || sink !== Audio.sink)
    Layout.fillWidth: true
    spacing: Tokens.spacing.small

    Item {
        implicitWidth: muteIcon.implicitWidth + Tokens.padding.small
        implicitHeight: implicitWidth

        StateLayer {
            radius: Tokens.rounding.full
            onClicked: vol.sink.audio.muted = !vol.sink.audio.muted
        }

        MaterialIcon {
            id: muteIcon

            anchors.centerIn: parent
            animate: true
            text: vol.muted ? "volume_off" : (vol.sink?.audio?.volume ?? 0) < 0.01 ? "volume_mute" : "volume_up"
            color: vol.muted ? Colours.palette.m3error : Colours.palette.m3onSurfaceVariant
        }
    }

    StyledSlider {
        Layout.fillWidth: true
        implicitHeight: Tokens.padding.medium * 2

        value: vol.muted ? 0 : (vol.sink?.audio?.volume ?? 0)
        onInteraction: value => {
            vol.sink.audio.muted = false;
            vol.sink.audio.volume = Math.max(0, Math.min(1, value));
        }
    }

    StyledText {
        // Fixed width so the slider does not resize while dragging (100% vs 9%)
        Layout.preferredWidth: pctMetrics.width
        horizontalAlignment: Text.AlignRight
        text: vol.muted ? "—" : `${Math.round((vol.sink?.audio?.volume ?? 0) * 100)}%`
        color: vol.muted ? Colours.palette.m3error : Colours.palette.m3onSurfaceVariant
        font: Tokens.font.body.small

        TextMetrics {
            id: pctMetrics

            font: Tokens.font.body.small
            text: "100%"
        }
    }
}
