import "root:/widgets"
import "root:/services"
import "root:/config"
import "components"
import "components/workspaces"
import Quickshell
import QtQuick

StyledRect {
    id: root

    required property ShellScreen screen

    function checkPopout(y: real): var {
        const spacing = Appearance.spacing.small;
        const aw = activeWindow.child;
        const awy = activeWindow.y + aw.y;
        const n = statusIconsInner.network;
        const ny = statusIcons.y + statusIconsInner.y + n.y - spacing / 2;
        const bls = statusIcons.y + statusIconsInner.y + statusIconsInner.bs - spacing / 2;
        const ble = statusIcons.y + statusIconsInner.y + statusIconsInner.be + spacing / 2;
        const b = statusIconsInner.battery;
        const by = statusIcons.y + statusIconsInner.y + b.y - spacing / 2;
        if (y >= awy && y <= awy + aw.implicitHeight) {
            Popouts.currentName = "activewindow";
            Popouts.currentCenter = Qt.binding(() => activeWindow.y + aw.y + aw.implicitHeight / 2);
            Popouts.hasCurrent = true;
        } else if (y >= ny && y <= ny + n.implicitHeight + spacing) {
            Popouts.currentName = "network";
            Popouts.currentCenter = Qt.binding(() => statusIcons.y + statusIconsInner.y + n.y + n.implicitHeight / 2);
            Popouts.hasCurrent = true;
        } else if (y >= bls && y <= ble) {
            Popouts.currentName = "bluetooth";
            Popouts.currentCenter = Qt.binding(() => statusIcons.y + statusIconsInner.y + statusIconsInner.bs + (statusIconsInner.be - statusIconsInner.bs) / 2);
            Popouts.hasCurrent = true;
        } else if (y >= by && y <= by + b.implicitHeight + spacing) {
            Popouts.currentName = "battery";
            Popouts.currentCenter = Qt.binding(() => statusIcons.y + statusIconsInner.y + b.y + b.implicitHeight / 2);
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

        ActiveWindow {
            id: activeWindow

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: workspaces.bottom
            anchors.bottom: tray.top
            anchors.margins: Appearance.spacing.large

            monitor: Brightness.getMonitorForScreen(root.screen)
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
