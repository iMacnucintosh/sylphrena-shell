pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Sylphrena.Config
import Sylphrena.I18n
import qs.components
import qs.services

ColumnLayout {
    id: root

    required property PopoutState popouts

    readonly property var activity: Activities.activityById(popouts.activityMenuId)

    // Fixed width so the action label never clips against the lobe padding.
    width: 280
    spacing: Tokens.spacing.small

    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: Tokens.padding.small
        Layout.rightMargin: Tokens.padding.extraSmall
        spacing: Tokens.spacing.small

        MaterialIcon {
            text: root.activity?.icon || "dashboard"
            color: Colours.palette.m3onSurfaceVariant
            fontStyle: Tokens.font.icon.medium
        }

        StyledText {
            Layout.fillWidth: true
            // Config stores the source string (e.g. "Games"); translate only for display.
            text: root.activity?.name ? Tr.tr(root.activity.name) : Tr.tr("Activity")
            font: Tokens.font.body.builders.medium.weight(Font.Medium).build()
            elide: Text.ElideRight
        }
    }

    StyledRect {
        Layout.fillWidth: true
        Layout.rightMargin: Tokens.padding.extraSmall
        radius: Tokens.rounding.medium
        color: Colours.layer(Colours.palette.m3surfaceContainerHighest, 2)

        implicitHeight: closeRow.implicitHeight + Tokens.padding.medium * 2

        StateLayer {
            anchors.fill: parent
            radius: parent.radius
            onClicked: {
                if (root.activity)
                    Activities.closeWindowsInActivity(root.activity.id);
                root.popouts.hasCurrent = false;
            }
        }

        RowLayout {
            id: closeRow

            anchors.fill: parent
            anchors.margins: Tokens.padding.medium
            spacing: Tokens.spacing.small

            MaterialIcon {
                text: "close"
                color: Colours.palette.m3onSurfaceVariant
            }

            StyledText {
                Layout.fillWidth: true
                text: Tr.tr("Close all windows")
                color: Colours.palette.m3onSurface
                elide: Text.ElideRight
            }
        }
    }
}
