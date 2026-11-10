pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Sylphrena.Config
import Sylphrena.I18n
import Sylphrena.Services
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common

PageBase {
    id: root

    // Lyrics backends, ordered to match config::LyricsBackend (Auto, Local, LRCLIB, NetEase)
    readonly property list<MenuItem> lyricsItems: [
        MenuItem {
            text: Tr.trCtx("Auto", "lyrics backend")
        },
        MenuItem {
            text: Tr.trCtx("Local", "lyrics backend")
        },
        MenuItem {
            text: "LRCLIB"
        },
        MenuItem {
            text: "NetEase"
        }
    ]

    // GPU types, ordered to match config::GpuType (Auto, Nvidia, Generic, None)
    readonly property list<MenuItem> gpuItems: [
        MenuItem {
            text: Tr.trCtx("Auto", "gpu type")
        },
        MenuItem {
            text: "NVIDIA"
        },
        MenuItem {
            text: Tr.trCtx("Generic", "gpu type")
        },
        MenuItem {
            text: Tr.trCtx("None", "gpu type")
        }
    ]

    property bool hydrationSettingsOpen: false

    title: Tr.tr("Dashboard")
    isSubPage: true

    component SettingRow: RowLayout {
        property alias label: settingLabel.text
        property alias subtext: settingSub.text
        property alias value: spin.value
        property alias from: spin.from
        property alias to: spin.to
        property alias stepSize: spin.stepSize
        signal moved(value: real)

        Layout.fillWidth: true
        // Same height with or without a subtext, so the rows line up evenly
        Layout.preferredHeight: 52
        spacing: Tokens.spacing.medium

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 0

            StyledText {
                id: settingLabel
                Layout.fillWidth: true
                font: Tokens.font.body.small
                elide: Text.ElideRight
            }

            StyledText {
                id: settingSub
                Layout.fillWidth: true
                visible: text.length > 0
                color: Colours.palette.m3outline
                font: Tokens.font.label.small
                elide: Text.ElideRight
            }
        }

        StyledSpinBox {
            id: spin
            cLayer: 2
            onValueModified: parent.moved(value)
        }
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        Variants {
            id: playerVariants

            model: [...new Set(Players.list.map(p => Players.getIdentity(p)).filter(id => id))]

            MenuItem {
                required property string modelData

                text: modelData
                icon: modelData === GlobalConfig.services.defaultPlayer ? "check" : ""
                activeIcon: "music_note"
            }
        }

        // General
        SectionHeader {
            first: true
            text: Tr.tr("General")
        }

        ToggleRow {
            first: true
            text: Tr.trCtx("Enabled", "toggle label")
            checked: Config.dashboard.enabled
            onToggled: GlobalConfig.dashboard.enabled = checked
        }

        ToggleRow {
            text: Tr.tr("Show on hover")
            subtext: Tr.tr("Reveal when the cursor reaches the screen edge")
            checked: Config.dashboard.showOnHover
            onToggled: GlobalConfig.dashboard.showOnHover = checked
        }

        ToggleRow {
            last: true
            text: Tr.tr("Show clock seconds")
            subtext: Tr.tr("Display seconds for the clock in the main panel")
            checked: Config.dashboard.showClockSeconds
            onToggled: GlobalConfig.dashboard.showClockSeconds = checked
        }

        // Widget carousel — centre of the Dashboard tab; one widget at a time
        SectionHeader {
            text: Tr.tr("Widget carousel")
        }

        StyledText {
            Layout.fillWidth: true
            Layout.leftMargin: Tokens.padding.small
            Layout.rightMargin: Tokens.padding.small
            Layout.bottomMargin: Tokens.spacing.small
            text: Tr.tr("The centre of the Dashboard shows one widget at a time; switch with the dots, the wheel or by dragging. Enable and reorder them here.")
            color: Colours.palette.m3outline
            font: Tokens.font.label.small
            wrapMode: Text.Wrap
        }

        Repeater {
            model: DashWidgets.order

            delegate: ConnectedRect {
                id: card

                required property var modelData
                required property int index
                readonly property bool isHydration: modelData.id === "hydration"

                Layout.fillWidth: true
                first: index === 0
                last: index === DashWidgets.order.length - 1
                implicitHeight: cardCol.implicitHeight + Tokens.padding.medium * 2

                ColumnLayout {
                    id: cardCol

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: Tokens.padding.medium
                    anchors.leftMargin: Tokens.padding.largeIncreased
                    anchors.rightMargin: Tokens.padding.largeIncreased
                    spacing: Tokens.spacing.medium

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Tokens.spacing.medium

                        MaterialIcon {
                            id: cardIcon

                            text: card.modelData.icon
                            color: Colours.palette.m3onSurfaceVariant
                            fontStyle: Tokens.font.icon.medium
                            Layout.alignment: Qt.AlignVCenter
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            StyledText {
                                Layout.fillWidth: true
                                text: card.modelData.title
                                font: Tokens.font.body.small
                                elide: Text.ElideRight
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: card.isHydration && Hydration.enabled && root.hydrationSettingsOpen
                                    ? Tr.tr("%1 ml · reminder every %2 min").arg(GlobalConfig.addons.hydration.dailyGoalMl).arg(GlobalConfig.addons.hydration.reminderMinutes)
                                    : card.isHydration && !Hydration.enabled
                                        ? Tr.tr("Off — also stops the reminders and the tracking")
                                        : card.modelData.subtext
                                color: Colours.palette.m3outline
                                font: Tokens.font.label.small
                                elide: Text.ElideRight
                                wrapMode: Text.NoWrap
                            }
                        }

                        IconButton {
                            isRound: true
                            icon: "arrow_upward"
                            type: IconButton.Text
                            font: Tokens.font.icon.builders.small.weight(Font.Bold).build()
                            padding: Tokens.padding.small
                            enabled: card.index !== 0
                            opacity: enabled ? 1 : 0.38
                            Layout.alignment: Qt.AlignVCenter
                            onClicked: DashWidgets.move(card.modelData.id, -1)
                        }

                        IconButton {
                            isRound: true
                            icon: "arrow_downward"
                            type: IconButton.Text
                            font: Tokens.font.icon.builders.small.weight(Font.Bold).build()
                            padding: Tokens.padding.small
                            enabled: card.index !== DashWidgets.order.length - 1
                            opacity: enabled ? 1 : 0.38
                            Layout.alignment: Qt.AlignVCenter
                            onClicked: DashWidgets.move(card.modelData.id, 1)
                        }

                        IconButton {
                            visible: card.isHydration && Hydration.enabled
                            isRound: true
                            icon: root.hydrationSettingsOpen ? "expand_less" : "expand_more"
                            type: IconButton.Text
                            font: Tokens.font.icon.builders.small.weight(Font.Bold).build()
                            padding: Tokens.padding.small
                            Layout.alignment: Qt.AlignVCenter
                            onClicked: root.hydrationSettingsOpen = !root.hydrationSettingsOpen
                        }

                        StyledSwitch {
                            Layout.alignment: Qt.AlignVCenter
                            checked: DashWidgets.isEnabled(card.modelData.id)
                            onToggled: {
                                DashWidgets.setEnabled(card.modelData.id, checked);
                                if (card.isHydration)
                                    root.hydrationSettingsOpen = checked;
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        visible: card.isHydration && Hydration.enabled && root.hydrationSettingsOpen
                        // Line the options up with the title, not with the icon
                        Layout.leftMargin: cardIcon.width + Tokens.spacing.medium
                        spacing: 0

                        SettingRow {
                            label: Tr.tr("Daily goal")
                            subtext: Tr.tr("Target water intake per day (ml)")
                            value: GlobalConfig.addons.hydration.dailyGoalMl
                            from: 500
                            to: 8000
                            stepSize: 100
                            onMoved: v => Hydration.setDailyGoal(v)
                        }

                        SettingRow {
                            label: Tr.tr("Reminder interval")
                            subtext: Tr.tr("Minutes without a sip before a reminder")
                            value: GlobalConfig.addons.hydration.reminderMinutes
                            from: 5
                            to: 120
                            stepSize: 5
                            onMoved: v => Hydration.setReminderMinutes(v)
                        }

                        SettingRow {
                            label: Tr.tr("Preset %1").arg(1)
                            subtext: Tr.tr("Quick-add button amount (ml)")
                            value: GlobalConfig.addons.hydration.presetMl0
                            from: 1
                            to: 1000
                            stepSize: 1
                            onMoved: v => Hydration.setPreset(0, v)
                        }

                        SettingRow {
                            label: Tr.tr("Preset %1").arg(2)
                            value: GlobalConfig.addons.hydration.presetMl1
                            from: 1
                            to: 1000
                            stepSize: 1
                            onMoved: v => Hydration.setPreset(1, v)
                        }

                        SettingRow {
                            label: Tr.tr("Preset %1").arg(3)
                            value: GlobalConfig.addons.hydration.presetMl2
                            from: 1
                            to: 1000
                            stepSize: 1
                            onMoved: v => Hydration.setPreset(2, v)
                        }

                        SettingRow {
                            label: Tr.tr("Preset %1").arg(4)
                            value: GlobalConfig.addons.hydration.presetMl3
                            from: 1
                            to: 1000
                            stepSize: 1
                            onMoved: v => Hydration.setPreset(3, v)
                        }
                    }
                }
            }
        }

        // Tabs
        SectionHeader {
            text: Tr.tr("Tabs")
        }

        ToggleRow {
            first: true
            text: Tr.tr("Dashboard")
            checked: Config.dashboard.showDashboard
            onToggled: GlobalConfig.dashboard.showDashboard = checked
        }

        ToggleRow {
            text: Tr.tr("Media")
            checked: Config.dashboard.showMedia
            onToggled: GlobalConfig.dashboard.showMedia = checked
        }

        ToggleRow {
            text: Tr.tr("Performance")
            checked: Config.dashboard.showPerformance
            onToggled: GlobalConfig.dashboard.showPerformance = checked
        }

        ToggleRow {
            last: true
            text: Tr.tr("Weather")
            checked: Config.dashboard.showWeather
            onToggled: GlobalConfig.dashboard.showWeather = checked
        }

        // Performance widgets
        SectionHeader {
            text: Tr.tr("Performance widgets")
        }

        ToggleRow {
            first: true
            text: Tr.tr("Battery")
            checked: Config.dashboard.performance.showBattery
            onToggled: GlobalConfig.dashboard.performance.showBattery = checked
        }

        ToggleRow {
            text: Tr.tr("GPU")
            checked: Config.dashboard.performance.showGpu
            onToggled: GlobalConfig.dashboard.performance.showGpu = checked
        }

        ToggleRow {
            text: Tr.tr("CPU")
            checked: Config.dashboard.performance.showCpu
            onToggled: GlobalConfig.dashboard.performance.showCpu = checked
        }

        ToggleRow {
            text: Tr.tr("Memory")
            checked: Config.dashboard.performance.showMemory
            onToggled: GlobalConfig.dashboard.performance.showMemory = checked
        }

        ToggleRow {
            text: Tr.tr("Storage")
            checked: Config.dashboard.performance.showStorage
            onToggled: GlobalConfig.dashboard.performance.showStorage = checked
        }

        ToggleRow {
            last: true
            text: Tr.tr("Network")
            checked: Config.dashboard.performance.showNetwork
            onToggled: GlobalConfig.dashboard.performance.showNetwork = checked
        }

        // Polling — media/stats refresh used by the dashboard surfaces
        SectionHeader {
            text: Tr.tr("Polling")
        }

        StepperRow {
            first: true
            label: Tr.tr("Media refresh")
            // TRANSLATORS: ms is the millisecond unit, leave it untranslated
            subtext: Tr.tr("How often the media position updates (ms)")
            value: GlobalConfig.dashboard.mediaUpdateInterval
            from: 100
            to: 2000
            stepSize: 50
            onMoved: v => GlobalConfig.dashboard.mediaUpdateInterval = v
        }

        StepperRow {
            last: true
            label: Tr.tr("System stats refresh")
            // TRANSLATORS: CPU and GPU are hardware abbreviations, leave them untranslated
            subtext: Tr.tr("CPU, memory and GPU update interval (seconds)")
            value: GlobalConfig.dashboard.resourceUpdateInterval / 1000
            from: 0.5
            to: 10
            stepSize: 0.5
            onMoved: v => GlobalConfig.dashboard.resourceUpdateInterval = Math.round(v * 1000)
        }

        // Media & lyrics
        SectionHeader {
            text: Tr.tr("Media & lyrics")
        }

        SelectRow {
            first: true
            label: Tr.tr("Lyrics backend")
            subtext: Tr.tr("Source used to fetch synced lyrics")
            menuItems: root.lyricsItems
            active: root.lyricsItems[Lyrics.preferredBackend] ?? root.lyricsItems[0]
            onSelected: item => Lyrics.preferredBackend = root.lyricsItems.indexOf(item)
        }

        SelectRow {
            last: true
            label: Tr.tr("Default player")
            subtext: Tr.tr("Preferred media player when several are open")
            menuItems: playerVariants.instances
            active: menuItems.find(i => i.text === GlobalConfig.services.defaultPlayer) ?? null
            fallbackIcon: "music_note"
            fallbackText: GlobalConfig.services.defaultPlayer || Tr.trCtx("Auto", "default media player")
            onSelected: item => GlobalConfig.services.defaultPlayer = item.text
        }

        // Service tuning (visualiser / GPU probe used by dashboard performance)
        SectionHeader {
            text: Tr.tr("Service tuning")
        }

        StepperRow {
            first: true
            // TRANSLATORS: bars of a spectrum analyser, not the taskbar
            label: Tr.tr("Visualiser bars")
            subtext: Tr.tr("Number of bars in the audio visualisers")
            value: GlobalConfig.services.visualiserBars
            from: 10
            to: 120
            stepSize: 2
            onMoved: v => GlobalConfig.services.visualiserBars = v
        }

        SelectRow {
            last: true
            label: Tr.tr("GPU")
            subtext: Gpu.name ? Tr.tr("Monitoring: %1").arg(Gpu.name) : Tr.tr("Override for GPU type")
            menuOnTop: true
            menuItems: root.gpuItems
            active: root.gpuItems[GlobalConfig.services.gpuType]
            onSelected: item => GlobalConfig.services.gpuType = root.gpuItems.indexOf(item)
        }

        // Behaviour
        SectionHeader {
            text: Tr.tr("Behaviour")
        }

        StepperRow {
            first: true
            last: true
            label: Tr.tr("Drag threshold")
            subtext: Tr.tr("Pixels dragged before the dashboard opens")
            value: Config.dashboard.dragThreshold
            from: 0
            to: 200
            stepSize: 5
            onMoved: v => GlobalConfig.dashboard.dragThreshold = v
        }
    }
}
