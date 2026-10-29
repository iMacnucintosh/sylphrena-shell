pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import M3Shapes
import qs.components
import qs.services

// Session power actions under Fetch — same Material You shapes as ResourcePanel.
StyledRect {
    id: root

    readonly property real fontScale: {
        const diff = width / 391 - 1;
        return 1 + Math.pow(Math.abs(diff), 0.8) * Math.sign(diff);
    }

    // Match ResourcePanel tile size (~1/3 of that row's cell).
    readonly property int buttonSize: Math.round(Math.min(96 * fontScale, Math.min(width * 0.28, height * 0.55)))

    radius: Theme.rounding.medium
    color: Theme.palette.m3surfaceContainer

    function runPower(argv: list<string>): void {
        // Cover the greeter before systemd tears down Hyprland so the VT
        // spam + Caelestia mark never flash on the way out.
        Shutdown.arm(argv);
    }

    RowLayout {
        anchors.centerIn: parent
        spacing: Theme.spacing.large

        PowerButton {
            icon: "power_settings_new"
            shape: MaterialShape.Pentagon
            shapeColour: Theme.palette.m3errorContainer
            iconColour: Theme.palette.m3error
            hoverShape: Theme.palette.m3error
            hoverIcon: Theme.palette.m3onError
            command: ["systemctl", "poweroff"]
        }

        PowerButton {
            icon: "restart_alt"
            shape: MaterialShape.Gem
            shapeColour: Theme.palette.m3primaryContainer
            iconColour: Theme.palette.m3primary
            hoverShape: Theme.palette.m3primary
            hoverIcon: Theme.palette.m3onPrimary
            command: ["systemctl", "reboot"]
        }
    }

    component PowerButton: Item {
        id: button

        required property string icon
        required property int shape
        required property color shapeColour
        required property color iconColour
        required property color hoverShape
        required property color hoverIcon
        required property list<string> command

        implicitWidth: root.buttonSize
        implicitHeight: root.buttonSize

        MaterialShape {
            id: shape

            anchors.fill: parent
            shape: button.shape
            color: mouse.containsMouse ? button.hoverShape : button.shapeColour
            scale: mouse.pressed ? 0.85 : mouse.containsMouse ? 0.95 : 1

            Behavior on color {
                CAnim {}
            }
            Behavior on scale {
                Anim {
                    type: Anim.FastSpatial
                }
            }
        }

        MaterialIcon {
            anchors.centerIn: shape
            text: button.icon
            color: mouse.containsMouse ? button.hoverIcon : button.iconColour
            iconSize: Math.round(Theme.font.iconLarge * root.fontScale)
            z: 1
        }

        MouseArea {
            id: mouse

            anchors.fill: shape
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.runPower(button.command)
        }
    }
}
