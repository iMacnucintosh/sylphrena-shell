pragma ComponentBehavior: Bound

import QtQuick.Layouts
import Sylphrena.Config
import Sylphrena.I18n
import qs.modules.nexus
import qs.modules.nexus.common

PageBase {
    id: root

    title: Tr.tr("Workspaces")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        ToggleRow {
            first: true
            text: Tr.trCtx("Active indicator", "bar workspaces")
            checked: Config.bar.workspaces.activeIndicator
            onToggled: GlobalConfig.bar.workspaces.activeIndicator = checked
        }

        ToggleRow {
            text: Tr.trCtx("Active trail", "bar workspaces")
            checked: Config.bar.workspaces.activeTrail
            onToggled: GlobalConfig.bar.workspaces.activeTrail = checked
        }

        ToggleRow {
            text: Tr.trCtx("Occupied background", "bar workspaces")
            checked: Config.bar.workspaces.occupiedBg
            onToggled: GlobalConfig.bar.workspaces.occupiedBg = checked
        }

        ToggleRow {
            text: Tr.trCtx("Dim desktops on another monitor", "bar workspaces")
            subtext: Tr.tr("With several monitors, the desktops open on another one look faded")
            checked: !Config.bar.workspaces.perMonitor
            onToggled: GlobalConfig.bar.workspaces.perMonitor = !checked
        }

        ToggleRow {
            text: Tr.tr("Window preview on hover")
            subtext: Tr.tr("Hovering an app icon of a desktop in the bar shows a live thumbnail of its window; click it to go there")
            checked: GlobalConfig.activities.windowPreview
            onToggled: GlobalConfig.activities.windowPreview = checked
        }

        NavRow {
            last: true
            icon: "dashboard_customize"
            text: Tr.tr("Window icons on the desktops")
            subtext: Tr.tr("Showing windows and their icons lives in Activities → Desktops in the bar")
            onClicked: root.nState.currentPageIdx = PageRegistry.idxOf("activities")
        }
    }
}
