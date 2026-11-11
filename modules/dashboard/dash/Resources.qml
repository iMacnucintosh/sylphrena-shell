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
            reading: Cpu.percentage
        }

        Resource {
            icon: "memory_alt"
            reading: Memory.percentage
            fgColour: Colours.palette.m3tertiary
        }

        // Storage, unless an extension contributes a ring with something to show (e.g. the Razer
        // mouse battery): then it takes this slot. One item that switches content (toggling two
        // items' visibility left the ring collapsed: its size follows its height, which the layout
        // only gives once visible).
        Resource {
            readonly property var ext: Extensions.resourceRing

            icon: ext ? ext.ring.icon : "hard_disk"
            reading: ext ? ext.ring.value : Storage.percentage
            fgColour: ext?.ring.warn ? Colours.palette.m3error : Colours.palette.m3secondary

            MaterialIcon {
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: Tokens.padding.small
                visible: !!parent.ext?.ring.badge
                text: parent.ext?.ring.badge ?? ""
                fill: 1
                fontStyle: Tokens.font.icon.small
                color: Colours.palette.m3tertiary
            }
        }
    }
    // StatRing: only follows changes of 2 % or more (see components/controls/StatRing.qml)
    component Resource: StatRing {
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
