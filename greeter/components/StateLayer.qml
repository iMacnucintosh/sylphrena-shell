import QtQuick
import qs.services

// Simplified Caelestia state layer: hover + press wash inside the parent's
// rounded shape (Rectangle parents expose `radius`).
MouseArea {
    id: root

    property bool disabled
    property alias color: base.color
    readonly property alias rect: base

    anchors.fill: parent
    enabled: !disabled
    hoverEnabled: true
    cursorShape: disabled ? undefined : Qt.PointingHandCursor

    StyledRect {
        id: base

        anchors.fill: parent
        color: Theme.palette.m3onSurface
        radius: root.parent?.radius ?? 0
        opacity: root.pressed ? 0.12 : root.containsMouse ? 0.08 : 0

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }
}
