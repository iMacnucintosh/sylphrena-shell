import "root:/widgets"
import "root:/services"
import "root:/config"
import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Controls

Item {
    id: root

    required property PersistentProperties visibilities
    readonly property real nonAnimWidth: view.implicitWidth + viewWrapper.anchors.margins * 2

    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom

    implicitWidth: nonAnimWidth
    implicitHeight: tabs.implicitHeight + tabs.anchors.topMargin + view.implicitHeight + viewWrapper.anchors.margins * 2

    Tabs {
        id: tabs

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: Appearance.padding.normal
        anchors.margins: Appearance.padding.large

        nonAnimWidth: root.nonAnimWidth
        currentIndex: view.currentIndex
    }

    ClippingRectangle {
        id: viewWrapper

        anchors.top: tabs.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: Appearance.padding.large

        radius: Appearance.rounding.normal
        color: "transparent"

        SwipeView {
            id: view

            anchors.fill: parent

            currentIndex: tabs.currentIndex

            ClippingWrapperRectangle {
                id: dash

                radius: Appearance.rounding.normal
                color: "transparent"

                Dash {
                    shouldUpdate: visible && dash.ListView.isCurrentItem
                }
            }

            ClippingWrapperRectangle {
                id: media

                radius: Appearance.rounding.normal
                color: "transparent"

                Media {
                    shouldUpdate: visible && media.ListView.isCurrentItem
                }
            }

            ClippingWrapperRectangle {
                radius: Appearance.rounding.normal
                color: "transparent"

                Performance {}
            }
        }
    }

    Behavior on implicitWidth {
        NumberAnimation {
            duration: Appearance.anim.durations.large
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.anim.curves.emphasized
        }
    }

    Behavior on implicitHeight {
        NumberAnimation {
            duration: Appearance.anim.durations.large
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.anim.curves.emphasized
        }
    }
}
