pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Sylphrena.Config
import Sylphrena.I18n
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common

PageBase {
    id: root

    property bool timersSettingsOpen: false

    title: Tr.tr("Clock")
    isSubPage: true

    // Same inline spin pattern as ComplementsPage hydration card (no nested ConnectedRect).
    component SettingRow: RowLayout {
        property alias label: settingLabel.text
        property alias subtext: settingSub.text
        property alias value: spin.value
        property alias from: spin.from
        property alias to: spin.to
        property alias stepSize: spin.stepSize
        signal moved(value: real)

        Layout.fillWidth: true
        spacing: Tokens.spacing.medium

        ColumnLayout {
            Layout.fillWidth: true
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

        // Timers live inside the clock popout; expose enable + presets here.
        // Complements keeps the same addons.timers.enabled state.
        ConnectedRect {
            id: timersCard

            last: true
            Layout.fillWidth: true
            implicitHeight: timersCol.implicitHeight + Tokens.padding.medium * 2

            ColumnLayout {
                id: timersCol

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
                        text: "timer"
                        color: Colours.palette.m3onSurfaceVariant
                        fontStyle: Tokens.font.icon.medium
                        Layout.alignment: Qt.AlignVCenter
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        StyledText {
                            Layout.fillWidth: true
                            text: Tr.tr("Timers")
                            font: Tokens.font.body.small
                            elide: Text.ElideRight
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: Timers.enabled
                                ? (root.timersSettingsOpen
                                    // TRANSLATORS: %1-%4 = timer preset durations in minutes
                                    ? Tr.tr("Presets: %1 · %2 · %3 · %4 min").arg(GlobalConfig.addons.timers.presetMins0).arg(GlobalConfig.addons.timers.presetMins1).arg(GlobalConfig.addons.timers.presetMins2).arg(GlobalConfig.addons.timers.presetMins3)
                                    : Tr.tr("Quick timers"))
                                : Tr.tr("Disabled — active timers are cleared")
                            color: Colours.palette.m3outline
                            font: Tokens.font.label.small
                            elide: Text.ElideRight
                            wrapMode: Text.NoWrap
                        }
                    }

                    IconButton {
                        visible: Timers.enabled
                        isRound: true
                        icon: root.timersSettingsOpen ? "expand_less" : "expand_more"
                        type: IconButton.Text
                        font: Tokens.font.icon.builders.small.weight(Font.Bold).build()
                        padding: Tokens.padding.small
                        Layout.alignment: Qt.AlignVCenter
                        onClicked: root.timersSettingsOpen = !root.timersSettingsOpen
                    }

                    StyledSwitch {
                        Layout.alignment: Qt.AlignVCenter
                        checked: GlobalConfig.addons.timers.enabled
                        onToggled: {
                            Timers.setEnabled(checked);
                            if (!checked)
                                root.timersSettingsOpen = false;
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    visible: Timers.enabled && root.timersSettingsOpen
                    spacing: Tokens.spacing.small

                    SettingRow {
                        // TRANSLATORS: %1 = preset index (1-based)
                        label: Tr.tr("Preset %1").arg(1)
                        subtext: Tr.tr("Quick timer button duration (min)")
                        value: GlobalConfig.addons.timers.presetMins0
                        from: 1
                        to: 600
                        stepSize: 1
                        onMoved: v => GlobalConfig.addons.timers.presetMins0 = v
                    }

                    SettingRow {
                        label: Tr.tr("Preset %1").arg(2)
                        subtext: Tr.tr("Quick timer button duration (min)")
                        value: GlobalConfig.addons.timers.presetMins1
                        from: 1
                        to: 600
                        stepSize: 1
                        onMoved: v => GlobalConfig.addons.timers.presetMins1 = v
                    }

                    SettingRow {
                        label: Tr.tr("Preset %1").arg(3)
                        subtext: Tr.tr("Quick timer button duration (min)")
                        value: GlobalConfig.addons.timers.presetMins2
                        from: 1
                        to: 600
                        stepSize: 1
                        onMoved: v => GlobalConfig.addons.timers.presetMins2 = v
                    }

                    SettingRow {
                        label: Tr.tr("Preset %1").arg(4)
                        subtext: Tr.tr("Quick timer button duration (min)")
                        value: GlobalConfig.addons.timers.presetMins3
                        from: 1
                        to: 600
                        stepSize: 1
                        onMoved: v => GlobalConfig.addons.timers.presetMins3 = v
                    }
                }
            }
        }
    }
}
