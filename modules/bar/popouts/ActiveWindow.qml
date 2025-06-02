import "root:/widgets"
import "root:/services"
import "root:/utils"
import "root:/config"
import Quickshell.Widgets
import Quickshell.Wayland
import QtQuick

Item {
    id: root

    implicitWidth: child.implicitWidth
    implicitHeight: child.implicitHeight

    Column {
        id: child

        anchors.centerIn: parent
        spacing: Appearance.spacing.normal

        StyledText {
            text: Hyprland.activeClient?.title ?? ""

            elide: Text.ElideRight
            width: preview.implicitWidth
        }

        StyledText {
            text: Hyprland.activeClient?.wmClass ?? ""

            elide: Text.ElideRight
            width: preview.implicitWidth
        }

        ClippingWrapperRectangle {
            color: "transparent"
            radius: Appearance.rounding.small

            ScreencopyView {
                id: preview

                captureSource: ToplevelManager.toplevels.values.find(t => t.title === Hyprland.activeClient?.title) ?? null
                live: true

                constraintSize.width: BarConfig.sizes.windowPreviewSize
                constraintSize.height: BarConfig.sizes.windowPreviewSize
            }
        }
    }
}
