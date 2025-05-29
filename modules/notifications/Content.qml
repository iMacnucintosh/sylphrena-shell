import "root:/widgets"
import "root:/services"
import "root:/config"
import Quickshell
import Quickshell.Widgets
import QtQuick

Item {
    id: root

    readonly property int padding: Appearance.padding.large

    anchors.top: parent.top
    anchors.bottom: parent.bottom
    anchors.right: parent.right

    implicitWidth: NotifsConfig.sizes.width + padding * 2
    implicitHeight: {
        const count = list.count;
        if (count === 0)
            return 0;

        let height = (count - 1) * list.spacing;
        for (let i = 0; i < count; i++)
            height += list.itemAtIndex(i)?.nonAnimHeight ?? 0;

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

        return Math.min((screen?.height ?? 0) - BorderConfig.thickness * 2, height + padding * 2);
    }

    ClippingWrapperRectangle {
        anchors.fill: parent
        anchors.margins: root.padding

        color: "transparent"
        radius: Appearance.rounding.normal

        ListView {
            id: list

            model: ScriptModel {
                values: [...Notifs.popups].reverse()
            }

            anchors.fill: parent

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
        }
    }

    Behavior on implicitHeight {
        Anim {}
    }

    component Anim: NumberAnimation {
        duration: Appearance.anim.durations.expressiveDefaultSpatial
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
    }
}
