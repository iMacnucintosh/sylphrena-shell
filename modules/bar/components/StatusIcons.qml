import "root:/widgets"
import "root:/services"
import "root:/utils"
import "root:/config"
import Quickshell
import Quickshell.Services.UPower
import QtQuick

Item {
    id: root

    property color colour: Colours.palette.m3secondary

    clip: true
    implicitWidth: Math.max(network.implicitWidth, bluetooth.implicitWidth, devices.implicitWidth, battery.implicitWidth)
    implicitHeight: network.implicitHeight + bluetooth.implicitHeight + bluetooth.anchors.topMargin + (repeater.count > 0 ? devices.implicitHeight + devices.anchors.topMargin : 0) + (battery.active ? battery.implicitHeight + battery.anchors.topMargin : 0)

    MaterialIcon {
        id: network

        animate: true
        text: Icons.getNetworkIcon(Network.active?.strength ?? 0)
        color: root.colour

        anchors.horizontalCenter: parent.horizontalCenter
    }

    MaterialIcon {
        id: bluetooth

        anchors.horizontalCenter: network.horizontalCenter
        anchors.top: network.bottom
        anchors.topMargin: Appearance.spacing.small

        animate: true
        text: Bluetooth.powered ? "bluetooth" : "bluetooth_disabled"
        color: root.colour
    }

    Column {
        id: devices

        anchors.horizontalCenter: bluetooth.horizontalCenter
        anchors.top: bluetooth.bottom
        anchors.topMargin: Appearance.spacing.small

        Repeater {
            id: repeater

            model: ScriptModel {
                values: Bluetooth.devices.filter(d => d.connected)
            }

            MaterialIcon {
                required property Bluetooth.Device modelData

                animate: true
                text: Icons.getBluetoothIcon(modelData.icon)
                color: root.colour
            }
        }
    }

    Loader {
        id: battery

        anchors.horizontalCenter: devices.horizontalCenter
        anchors.top: repeater.count > 0 ? devices.bottom : bluetooth.bottom
        anchors.topMargin: Appearance.spacing.small

        active: UPower.displayDevice.isLaptopBattery
        asynchronous: true

        sourceComponent: MaterialIcon {
            text: {
                const perc = UPower.displayDevice.percentage;
                const charging = !UPower.onBattery;
                if (perc === 1)
                    return charging ? "battery_charging_full" : "battery_full";
                let level = Math.floor(perc * 7);
                if (charging && (level === 4 || level === 1))
                    level--;
                return charging ? `battery_charging_${(level + 3) * 10}` : `battery_${level}_bar`;
            }
            color: !UPower.onBattery || UPower.displayDevice.percentage > 0.2 ? root.colour : Colours.palette.m3error
            fill: 1
        }
    }

    Behavior on implicitWidth {
        NumberAnimation {
            duration: Appearance.anim.durations.normal
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.anim.curves.emphasized
        }
    }

    Behavior on implicitHeight {
        NumberAnimation {
            duration: Appearance.anim.durations.normal
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.anim.curves.emphasized
        }
    }
}
