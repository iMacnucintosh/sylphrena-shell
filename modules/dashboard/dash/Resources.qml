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
        // takes this slot
        Resource {
            visible: !RazerMouse.shown
            icon: "hard_disk"
            value: Storage.percentage
            fgColour: Colours.palette.m3secondary
        }

        Resource {
            visible: RazerMouse.shown
            icon: "mouse"
            value: RazerMouse.percent / 100
            fgColour: RazerMouse.low ? Colours.palette.m3error : Colours.palette.m3secondary

            MaterialIcon {
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: Tokens.padding.small
                visible: RazerMouse.charging
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
