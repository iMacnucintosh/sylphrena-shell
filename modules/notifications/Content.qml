import "root:/widgets"
import "root:/services"
import "root:/config"
import Quickshell
import Quickshell.Widgets
import QtQuick

Item {
    id: root

    readonly property int padding: Appearance.padding.large

    anchors.bottom: parent.bottom
    anchors.right: parent.right

    implicitWidth: NotifsConfig.sizes.width + root.padding * 2
    implicitHeight: list.implicitHeight + root.padding * 2

    ClippingWrapperRectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: root.padding

        color: "transparent"
        radius: Appearance.rounding.normal

        ListView {
            id: list

            model: ScriptModel {
                values: [...Notifs.popups].reverse()
            }

            anchors.fill: parent

            implicitHeight: {
                let height = (count - 1) * spacing;
                for (let i = 0; i < count; i++)
                    height += itemAtIndex(i)?.nonAnimHeight ?? 0;

                const screen = QsWindow.window?.screen;
                const visibilities = Visibilities.screens[screen];
                const panel = Visibilities.panels[screen];
                if (visibilities && panel) {
                    if (visibilities.osd) {
                        const h = panel.osd.y - BorderConfig.rounding * 2;
                        if (height > h)
                            height = h;
                    }

                    if (visibilities.session) {
                        const h = panel.session.y - BorderConfig.rounding * 2;
                        if (height > h)
                            height = h;
                    }
                }

                return Math.max(61, Math.min((screen?.height ?? 0) - root.padding * 2 - BorderConfig.thickness * 2, height));
            }

            orientation: Qt.Vertical
            spacing: Appearance.spacing.smaller
            cacheBuffer: QsWindow.window?.screen.height ?? 0

            delegate: ClippingRectangle {
                id: wrapper

                required property Notifs.Notif modelData
                readonly property alias nonAnimHeight: notif.nonAnimHeight

                color: "transparent"
                radius: notif.radius
                implicitWidth: notif.width
                implicitHeight: notif.height

                Notification {
                    id: notif

                    modelData: wrapper.modelData
                }
            }

            move: Transition {
                Anim {
                    property: "y"
                }
            }

            displaced: Transition {
                Anim {
                    property: "y"
                }
            }

            Behavior on implicitHeight {
                Anim {}
            }
        }
    }

    component Anim: NumberAnimation {
        duration: Appearance.anim.durations.expressiveDefaultSpatial
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
    }
}
