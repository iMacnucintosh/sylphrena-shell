import QtQuick
import QtQuick.Layouts
import Sylphrena.Config
import Sylphrena.Services
import qs.components
import qs.components.controls
import qs.services

Item {
    id: root

    anchors.top: parent.top
    anchors.bottom: parent.bottom

    implicitWidth: layout.implicitWidth + layout.anchors.margins * 2

    ServiceRef {
        service: Cpu
    }

    ServiceRef {
        service: Memory
    }

    ServiceRef {
        service: Storage
    }

    ColumnLayout {
        id: layout

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.margins: Tokens.padding.large
        spacing: Tokens.spacing.medium

        Resource {
            icon: "memory"
            value: Cpu.percentage
        }

        Resource {
            icon: "memory_alt"
            value: Memory.percentage
            fgColour: Colours.palette.m3tertiary
        }

        // Storage, unless the Razer mouse complement is on and the mouse answers: then its battery
        // takes this slot. One item that switches content (toggling two items' visibility left the
        // ring collapsed: its size follows its height, which the layout only gives once visible).
        Resource {
            icon: RazerMouse.shown ? "mouse" : "hard_disk"
            value: RazerMouse.shown ? RazerMouse.percent / 100 : Storage.percentage
            fgColour: RazerMouse.shown && RazerMouse.low ? Colours.palette.m3error : Colours.palette.m3secondary

            MaterialIcon {
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: Tokens.padding.small
                visible: RazerMouse.shown && RazerMouse.charging
                text: "bolt"
                fill: 1
                fontStyle: Tokens.font.icon.small
                color: Colours.palette.m3tertiary
            }
        }
    }
    component Resource: CircularProgress {
        id: res

        required property string icon

        Layout.fillHeight: true
        implicitSize: height
        strokeWidth: Tokens.sizes.dashboard.resourceProgressThickness

        Behavior on clampedVal {
            Anim {}
        }

        MaterialIcon {
            anchors.centerIn: parent
            text: res.icon
            font: Tokens.font.icon.large
            color: res.fgColour
        }
    }
}
