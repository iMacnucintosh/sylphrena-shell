pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import M3Shapes
import qs.components
import qs.services
import qs.services as Svc

StyledRect {
    id: root

    readonly property real fontScale: {
        const diff = width / 391 - 1;
        return 1 + Math.pow(Math.abs(diff), 0.8) * Math.sign(diff);
    }

    implicitHeight: layout.implicitHeight + Theme.spacing.large * 2
    radius: Theme.rounding.extraLarge
    color: Theme.palette.m3surfaceContainer

    RowLayout {
        id: layout

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.margins: Theme.spacing.large
        spacing: Theme.spacing.large

        Resource {
            id: cpu

            icon: "memory"
            value: `${Math.round(Svc.Resources.cpu * 100)}%`
            fillValue: Svc.Resources.cpu
            colour: Theme.palette.m3primary
            shapeColour: Theme.palette.m3primaryContainer
            fillColour: Qt.alpha(Theme.palette.m3secondary, 0.3)
            shape: MaterialShape.Pentagon

            MaterialShape {
                x: cpu.mShape.pointAtAngle(45).x - implicitSize / 2 + Theme.spacing.medium
                y: Math.max(cpu.mShape.pointAtAngle(45).y - implicitSize / 2, 1 - Theme.spacing.large)
                shape: Svc.Resources.temp > 90 ? MaterialShape.SoftBurst : MaterialShape.Circle
                color: Svc.Resources.temp > 90 ? Theme.palette.m3errorContainer : Theme.palette.m3secondaryContainer
                implicitSize: {
                    const size = Math.round(tempLabel.implicitHeight * 2);
                    return size % 2 === 0 ? size : size + 1;
                }

                Behavior on color {
                    CAnim {}
                }

                StyledText {
                    id: tempLabel

                    anchors.centerIn: parent
                    text: Svc.Resources.temp ? `${Svc.Resources.temp}°` : "--"
                    color: Svc.Resources.temp > 90 ? Theme.palette.m3onErrorContainer : Theme.palette.m3secondary
                    widthAxis: 50
                    font.pixelSize: Math.round(Theme.font.titleMedium * (cpu.width / 112))
                }
            }
        }

        Resource {
            icon: "memory_alt"
            value: `${Math.round(Svc.Resources.mem * 100)}%`
            fillValue: Svc.Resources.mem
            colour: Theme.palette.m3tertiary
            shapeColour: Theme.palette.m3onTertiary
            fillColour: Qt.alpha(Theme.palette.m3tertiary, 0.3)
            shape: MaterialShape.Slanted
        }

        Resource {
            icon: "hard_disk"
            value: `${Math.round(Svc.Resources.disk * 100)}%`
            fillValue: Svc.Resources.disk
            colour: Theme.palette.m3secondary
            shapeColour: Theme.palette.m3secondaryContainer
            fillColour: Qt.alpha(Theme.palette.m3secondary, 0.4)
            shape: MaterialShape.Gem
        }
    }

    component Resource: Item {
        id: res

        required property string icon
        required property string value
        required property color colour
        required property color shapeColour
        property color fillColour
        property real fillValue: -1
        property alias shape: shape.shape
        readonly property alias mShape: shape

        Layout.fillWidth: true
        implicitHeight: width

        Behavior on shapeColour {
            CAnim {}
        }

        MaterialShape {
            id: shape

            implicitSize: res.width
            color: Qt.alpha(res.shapeColour, 1)
            opacity: res.shapeColour.a
            layer.enabled: true
        }

        Loader {
            anchors.fill: shape
            active: res.fillValue >= 0
            asynchronous: true
            layer.enabled: active
            layer.effect: Mask {
                maskSource: shape
            }

            sourceComponent: Item {
                WavyTopRect {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    implicitHeight: shape.implicitSize * res.fillValue
                    color: res.fillColour
                }
            }
        }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: -Theme.spacing.extraSmall

            MaterialIcon {
                Layout.alignment: Qt.AlignHCenter
                text: res.icon
                color: Theme.palette.m3secondary
                iconSize: Math.round(Theme.font.iconMedium * root.fontScale)
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: res.value
                color: res.colour
                widthAxis: 50
                font.pixelSize: Math.round(Theme.font.headlineLarge * root.fontScale)
            }
        }

        Behavior on fillValue {
            Anim {}
        }
    }
}
