pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Sylphrena.Config
import Sylphrena.I18n
import qs.components
import qs.services

// Bar popout of the keyboard layouts: the others to switch to, and the one in use. The same layouts and names as
// Nexus → Language & region (Hypr); Hyprland reports which one is active.
ColumnLayout {
    id: root

    // XKB holds four at most
    readonly property var entries: Hypr.shownKeyboardEntries().slice(0, 4)
    readonly property int active: Hypr.keyboard?.lastIpcObject?.active_layout_index ?? -1
    readonly property string activeLabel: root.entries[root.active] ? root.label(root.entries[root.active]) : ""

    function label(entry: string): string {
        // TRANSLATORS: %1 = layout code, %2 = layout name
        return Tr.trCtx("%1 - %2", "keyboard layout code and name").arg(entry.split(":")[0].toUpperCase()).arg(Hypr.keyboardName(entry));
    }

    spacing: Tokens.spacing.small
    width: Tokens.sizes.bar.kbLayoutWidth

    StyledText {
        Layout.topMargin: Tokens.padding.medium
        Layout.rightMargin: Tokens.padding.extraSmall
        text: Tr.tr("Keyboard layouts")
        font: Tokens.font.body.builders.medium.weight(Font.Medium).build()
    }

    Repeater {
        model: root.entries.map((entry, index) => ({ entry, index })).filter(e => e.index !== root.active)

        Item {
            id: row

            required property var modelData

            Layout.fillWidth: true
            Layout.rightMargin: Tokens.padding.extraSmall
            implicitHeight: Math.max(36, rowText.implicitHeight + Tokens.padding.small)

            StateLayer {
                id: layer

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                implicitHeight: parent.height - 4
                radius: Tokens.rounding.full
                onClicked: Quickshell.execDetached(["hyprctl", "switchxkblayout", "all", String(row.modelData.index)])
            }

            StyledText {
                id: rowText

                anchors.verticalCenter: layer.verticalCenter
                anchors.left: layer.left
                anchors.right: layer.right
                anchors.leftMargin: Tokens.padding.extraSmall
                anchors.rightMargin: Tokens.padding.extraSmall
                text: root.label(row.modelData.entry)
                elide: Text.ElideRight
            }
        }
    }

    Rectangle {
        visible: root.activeLabel.length > 0 && root.entries.length > 1
        Layout.fillWidth: true
        Layout.rightMargin: Tokens.padding.extraSmall
        Layout.topMargin: Tokens.spacing.small
        implicitHeight: 1
        color: Colours.palette.m3onSurfaceVariant
        opacity: 0.35
    }

    RowLayout {
        id: activeRow

        visible: root.activeLabel.length > 0
        Layout.fillWidth: true
        Layout.rightMargin: Tokens.padding.extraSmall
        Layout.topMargin: Tokens.spacing.small
        Layout.bottomMargin: Tokens.padding.small
        spacing: Tokens.spacing.small

        MaterialIcon {
            text: "keyboard"
            color: Colours.palette.m3primary
        }

        StyledText {
            Layout.fillWidth: true
            text: root.activeLabel
            elide: Text.ElideRight
            font: Tokens.font.body.builders.medium.weight(Font.Medium).build()
            color: Colours.palette.m3primary

            Behavior on text {
                SequentialAnimation {
                    Anim {
                        target: activeRow
                        property: "opacity"
                        to: 0
                        duration: 70
                    }
                    PropertyAction {}
                    Anim {
                        target: activeRow
                        property: "opacity"
                        to: 1
                        duration: 160
                    }
                }
            }
        }
    }
}
