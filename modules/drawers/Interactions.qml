import "root:/services"
import "root:/config"
import "root:/modules/osd" as Osd
import Quickshell
import QtQuick

MouseArea {
    id: root

    required property ShellScreen screen
    required property PersistentProperties visibilities

    property bool osdHovered
    property point dragStart

    function withinPanelHeight(panel: Item, x: real, y: real): bool {
        const panelY = BorderConfig.thickness + panel.y;
        return y >= panelY && y <= panelY + panel.height;
    }

    function inRightPanel(panel: Item, x: real, y: real): bool {
        return x > BorderConfig.thickness + panel.x && withinPanelHeight(panel, x, y);
    }

    function inTopPanel(panel: Item, x: real, y: real): bool {
        const panelX = BorderConfig.thickness + panel.x;
        return y < BorderConfig.thickness + panel.y + panel.height && x >= panelX && x <= panelX + panel.width;
    }

    anchors.fill: parent
    hoverEnabled: true

    onPressed: event => dragStart = Qt.point(event.x, event.y)

    Connections {
        target: Hyprland

        function onCursorPosChanged(): void {
            let {
                x,
                y
            } = Hyprland.cursorPos;
            x -= QsWindow.window.margins.left + Hyprland.focusedMonitor.x;
            y -= QsWindow.window.margins.top + Hyprland.focusedMonitor.y;

            // Show osd on hover
            const showOsd = root.inRightPanel(panels.osd, x, y);
            root.visibilities.osd = showOsd;
            root.osdHovered = showOsd;

            // Show/hide session on drag
            if (root.pressed && root.withinPanelHeight(panels.session, x, y)) {
                const dragX = x - root.dragStart.x;
                if (dragX < -SessionConfig.dragThreshold)
                    root.visibilities.session = true;
                else if (dragX > SessionConfig.dragThreshold)
                    root.visibilities.session = false;
            }

            const showDashboard = root.inTopPanel(panels.dashboard, x, y);
            root.visibilities.dashboard = showDashboard;
        }
    }

    Osd.Interactions {
        screen: root.screen
        visibilities: root.visibilities
        hovered: root.osdHovered
    }
}
