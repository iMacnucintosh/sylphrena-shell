

import "root:/widgets"
import "root:/services"
import "root:/utils"
import "root:/config"
import Quickshell.Wayland
import QtQuick

Item {
    id: root

    implicitWidth: child.implicitWidth
    implicitHeight: child.implicitHeight

    Column {
        id: child

        anchors.centerIn: parent

        StyledText {
            text: Hyprland.activeClient?.title ?? ""
        }

        StyledText {
            text: Hyprland.activeClient?.wmClass ?? ""
        }

        ScreencopyView {
            
        }
    }
}
