pragma ComponentBehavior: Bound

import QtQuick
import M3Shapes
import qs.components
import qs.services

Item {
    id: root

    required property int centerWidth
    readonly property color bgColour: Theme.palette.m3surfaceContainerHighest

    implicitWidth: Math.round(centerWidth * 0.62)
    implicitHeight: Math.round(implicitWidth * 0.72)

    MaterialShape {
        id: shape

        anchors.centerIn: parent
        implicitSize: root.implicitWidth
        shape: MaterialShape.ClamShell
        color: Qt.alpha(root.bgColour, 1)
        layer.enabled: true
    }

    MaterialIcon {
        anchors.centerIn: parent
        text: "person"
        color: Theme.palette.m3onSurfaceVariant
        iconSize: Math.round(root.centerWidth / 5)
        visible: pfp.status !== Image.Ready
    }

    Image {
        id: pfp

        anchors.fill: shape
        source: `file://${Theme.face}`
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        visible: status === Image.Ready
        layer.enabled: true
        layer.effect: Mask {
            maskSource: shape
        }
    }
}
