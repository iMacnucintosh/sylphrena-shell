pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import qs.components
import qs.services

// M3 dropdown over /usr/share/wayland-sessions. Hidden while there is only
// one session (the usual case once Plasma is gone).
Item {
    id: root

    property bool open: false
    readonly property var entries: Sessions.entries
    readonly property var current: Sessions.current

    visible: Sessions.multiple
    implicitWidth: pill.implicitWidth
    implicitHeight: pill.implicitHeight

    StyledRect {
        id: pill

        anchors.fill: parent

        color: Theme.palette.m3surfaceContainer
        radius: Theme.rounding.full

        implicitWidth: pillRow.implicitWidth + Theme.spacing.large * 2
        implicitHeight: pillRow.implicitHeight + Theme.spacing.small * 2

        StateLayer {
            onClicked: root.open = !root.open
        }

        RowLayout {
            id: pillRow

            anchors.centerIn: parent
            spacing: Theme.spacing.small

            MaterialIcon {
                text: "desktop_windows"
                color: Theme.palette.m3onSurfaceVariant
                iconSize: Theme.font.iconSmall
            }

            StyledText {
                text: root.current?.name ?? "Sesión"
                color: Theme.palette.m3onSurface
                font.pixelSize: Theme.font.bodySmall
            }

            MaterialIcon {
                text: "expand_more"
                color: Theme.palette.m3onSurfaceVariant
                iconSize: Theme.font.iconSmall
                rotation: root.open ? 180 : 0

                Behavior on rotation {
                    Anim {}
                }
            }
        }
    }

    StyledRect {
        id: menu

        anchors.horizontalCenter: parent.horizontalCenter
        y: -height - Theme.spacing.small

        width: Math.max(pill.width, menuColumn.implicitWidth + Theme.spacing.small * 2)
        height: menuColumn.implicitHeight + Theme.spacing.small * 2

        color: Theme.palette.m3surfaceContainerHigh
        radius: Theme.rounding.large
        visible: opacity > 0
        opacity: root.open ? 1 : 0
        scale: root.open ? 1 : 0.9
        transformOrigin: Item.Bottom

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }

        Behavior on scale {
            Anim {}
        }

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            blurMax: 15
            shadowColor: Qt.alpha(Theme.palette.m3shadow, 0.7)
        }

        ColumnLayout {
            id: menuColumn

            anchors.centerIn: parent
            spacing: 0

            Repeater {
                model: root.entries

                StyledRect {
                    id: item

                    required property var modelData
                    required property int index

                    readonly property bool selected: index === Sessions.index

                    Layout.preferredWidth: Math.max(pill.width, 260) - Theme.spacing.small * 2
                    implicitHeight: itemRow.implicitHeight + Theme.spacing.small * 2

                    color: item.selected ? Theme.palette.m3secondaryContainer : "transparent"
                    radius: Theme.rounding.medium

                    StateLayer {
                        onClicked: {
                            Sessions.select(item.index);
                            root.open = false;
                        }
                    }

                    RowLayout {
                        id: itemRow

                        anchors.fill: parent
                        anchors.leftMargin: Theme.spacing.medium
                        anchors.rightMargin: Theme.spacing.medium
                        spacing: Theme.spacing.small

                        MaterialIcon {
                            text: "check"
                            color: item.selected ? Theme.palette.m3onSecondaryContainer : "transparent"
                            iconSize: Theme.font.iconSmall
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: item.modelData.name
                            color: item.selected ? Theme.palette.m3onSecondaryContainer : Theme.palette.m3onSurface
                            font.pixelSize: Theme.font.bodySmall
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }
    }
}
