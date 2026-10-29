import QtQuick
import qs.components
import qs.services

Item {
    id: root

    readonly property string msg: Auth.message

    implicitHeight: Math.max(Math.round(Theme.font.bodySmall * 1.4), message.implicitHeight)

    StyledText {
        id: message

        anchors.left: parent.left
        anchors.right: parent.right

        text: root.msg
        color: Theme.palette.m3error
        font.pixelSize: Theme.font.bodySmall
        horizontalAlignment: Qt.AlignHCenter
        wrapMode: Text.WrapAtWordBoundaryOrAnywhere

        scale: root.msg ? 1 : 0.7
        opacity: root.msg ? 1 : 0

        Behavior on scale {
            Anim {}
        }

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }
}
