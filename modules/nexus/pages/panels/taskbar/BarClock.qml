pragma ComponentBehavior: Bound

import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.services
import qs.modules.nexus.common

PageBase {
    id: root

    title: Tr.tr("Clock")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        ToggleRow {
            first: true
            text: Tr.trCtx("Background", "taskbar clock: draw a background behind the clock")
            checked: Config.bar.clock.background
            onToggled: GlobalConfig.bar.clock.background = checked
        }

        ToggleRow {
            text: Tr.tr("Show date")
            checked: Config.bar.clock.showDate
            onToggled: GlobalConfig.bar.clock.showDate = checked
        }

        ToggleRow {
            text: Tr.tr("Show icon")
            checked: Config.bar.clock.showIcon
            onToggled: GlobalConfig.bar.clock.showIcon = checked
        }

        ToggleRow {
            text: Tr.tr("Show seconds")
            checked: Config.bar.clock.showSeconds
            onToggled: GlobalConfig.bar.clock.showSeconds = checked
        }

        // Timers live inside the clock popout, so expose the complement here
        // too; the hub stays in Complements for completeness.
        SectionHeader {
            text: Tr.tr("Timers")
        }

        ToggleRow {
            first: true
            last: true
            leadingIcon: "timer"
            text: Tr.trCtx("Enabled", "clock timers toggle")
            subtext: Timers.enabled
                ? Tr.tr("Quick timers from the clock popout")
                : Tr.tr("Disabled — active timers are cleared")
            checked: GlobalConfig.addons.timers.enabled
            onToggled: Timers.setEnabled(checked)
        }
    }
}
