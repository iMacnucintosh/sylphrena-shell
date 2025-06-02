import "root:/widgets"
import "root:/services"
import "root:/config"
import "components"
import "components/workspaces"
import Quickshell
import Quickshell.Widgets
import QtQuick

StyledRect {
    id: root

    required property ShellScreen screen

    function checkPopout(y: real): var {
        const aw = activeWindow.child
        const awy = activeWindow.y + aw.y
        if (y >= awy && y <= awy + aw.implicitHeight) {
            Popouts.currentName = "activewindow"
            Popouts.currentCenter = Qt.binding(() => activeWindow.y + aw.y + aw.implicitHeight / 2);
            Popouts.hasCurrent = true;
        } else {
            Popouts.hasCurrent = false;
        }
    }

    anchors.top: parent.top
    anchors.bottom: parent.bottom

    implicitWidth: child.implicitWidth + BorderConfig.thickness

    color: BorderConfig.colour

    Component.onCompleted: Visibilities.bars[screen] = this

    MouseArea {
        anchors.fill: parent

        hoverEnabled: true

        onPositionChanged: event => root.checkPopout(event.y)

        onContainsMouseChanged: {
            if (!containsMouse)
                Popouts.hasCurrent = false;
        }
    }

    Item {
        id: child

        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right

        implicitWidth: Math.max(osIcon.implicitWidth, workspaces.implicitWidth, activeWindow.implicitWidth, tray.implicitWidth, clock.implicitWidth, statusIcons.implicitWidth, power.implicitWidth)

        OsIcon {
            id: osIcon

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: Appearance.padding.large
        }

        StyledClippingRect {
            id: workspaces

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: osIcon.bottom
            anchors.topMargin: Appearance.spacing.normal

            radius: Appearance.rounding.full
            color: Colours.palette.m3surfaceContainer

            implicitWidth: workspacesInner.implicitWidth + Appearance.spacing.small
            implicitHeight: workspacesInner.implicitHeight + Appearance.spacing.small * 2

            Workspaces {
                id: workspacesInner

                anchors.centerIn: parent
            }
        }

        MouseArea {
            anchors.top: workspaces.bottom
            anchors.bottom: activeWindow.top
            anchors.left: parent.left
            anchors.right: parent.right

            onWheel: event => {
                if (event.angleDelta.y > 0)
                    Audio.setVolume(Audio.volume + 0.1);
                else if (event.angleDelta.y < 0)
                    Audio.setVolume(Audio.volume - 0.1);
            }
        }

        ActiveWindow {
            id: activeWindow

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: workspaces.bottom
            anchors.bottom: tray.top
            anchors.margins: Appearance.spacing.large
        }

        MouseArea {
            anchors.top: workspaces.bottom
            anchors.bottom: activeWindow.top
            anchors.left: parent.left
            anchors.right: parent.right

            onWheel: event => {
                const monitor = Brightness.getMonitorForScreen(root.screen);
                if (event.angleDelta.y > 0)
                    monitor.setBrightness(monitor.brightness + 0.1);
                else if (event.angleDelta.y < 0)
                    monitor.setBrightness(monitor.brightness - 0.1);
            }
        }

        Tray {
            id: tray

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: clock.top
            anchors.bottomMargin: Appearance.spacing.larger
        }

        Clock {
            id: clock

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: statusIcons.top
            anchors.bottomMargin: Appearance.spacing.normal
        }

        StyledRect {
            id: statusIcons

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: power.top
            anchors.bottomMargin: Appearance.spacing.normal

            radius: Appearance.rounding.full
            color: Colours.palette.m3surfaceContainer

            implicitHeight: statusIconsInner.implicitHeight + Appearance.padding.normal * 2

            StatusIcons {
                id: statusIconsInner

                anchors.centerIn: parent
            }
        }

        Power {
            id: power

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Appearance.padding.large
        }
    }
}
