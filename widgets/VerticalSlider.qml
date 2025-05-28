import "root:/widgets"
import "root:/services"
import "root:/config"
import QtQuick
import QtQuick.Controls
import QtQuick.Effects

Slider {
    id: root

    required property string icon
    property real oldValue

    orientation: Qt.Vertical

    background: StyledRect {
        color: Colours.alpha(Colours.palette.m3surfaceContainer, true)
        radius: Appearance.rounding.full

        StyledRect {
            anchors.left: parent.left
            anchors.right: parent.right

            y: root.handle.y
            implicitHeight: parent.height - y

            color: Colours.alpha(Colours.palette.m3secondary, true)
            radius: Appearance.rounding.full
        }
    }

    handle: Item {
        id: handle

        property bool moving

        y: root.visualPosition * (root.availableHeight - height)
        implicitWidth: root.width
        implicitHeight: root.width

        RectangularShadow {
            anchors.fill: parent
            radius: rect.radius
            color: Colours.palette.m3shadow
            blur: 5
            spread: 0
        }

        StyledRect {
            id: rect

            anchors.fill: parent

            color: Colours.alpha(Colours.palette.m3inverseSurface, true)
            radius: Appearance.rounding.full

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onPressed: event => event.accepted = false
            }

            MaterialIcon {
                id: icon

                animate: true
                text: root.icon
                color: Colours.palette.m3inverseOnSurface
                anchors.centerIn: parent

                states: State {
                    name: "value"
                    when: handle.moving

                    PropertyChanges {
                        icon.animate: false
                        icon.text: Math.round(root.value * 100)
                        icon.font.pointSize: Appearance.font.size.small
                        icon.font.family: Appearance.font.family.sans
                    }
                }

                transitions: Transition {
                    NumberAnimation {
                        target: icon
                        property: "scale"
                        from: 1
                        to: 0
                        duration: Appearance.anim.durations.normal
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Appearance.anim.curves.standardAccel
                    }
                    PropertyAction {
                        target: icon
                        properties: "animate,text,font.pointSize,font.family"
                    }
                    NumberAnimation {
                        target: icon
                        property: "scale"
                        from: 0
                        to: 1
                        duration: Appearance.anim.durations.normal
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Appearance.anim.curves.standardDecel
                    }
                }
            }
        }
    }

    onPressedChanged: handle.moving = pressed

    onValueChanged: {
        if (Math.abs(value - oldValue) < 0.01)
            return;
        oldValue = value;
        handle.moving = true;
        stateChangeDelay.restart();
    }

    Timer {
        id: stateChangeDelay

        interval: 500
        onTriggered: {
            if (!root.pressed)
                handle.moving = false;
        }
    }

    Behavior on value {
        NumberAnimation {
            duration: Appearance.anim.durations.large
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.anim.curves.standard
        }
    }
}
