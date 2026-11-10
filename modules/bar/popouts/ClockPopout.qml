pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Sylphrena.Components
import Sylphrena.Config
import Sylphrena.I18n
import qs.components
import qs.components.controls
import qs.modules.dashboard.dash
import qs.services

ColumnLayout {
    id: root

    required property ScreenState screenState

    width: 340
    spacing: Tokens.spacing.medium

    function customMinutes(): real {
        const field = customMins.contentItem;
        if (field?.text !== undefined) {
            const parsed = customMins.valueFromText(field.text, customMins.locale);
            if (!Number.isNaN(parsed))
                return Math.min(customMins.to, Math.max(customMins.from, parsed));
        }
        return customMins.value;
    }

    function addCustomTimer(): void {
        const mins = root.customMinutes();
        customMins.value = mins;
        Timers.addMinutes(mins, "");
    }

    StyledRect {
        Layout.fillWidth: true
        implicitHeight: calendar.implicitHeight
        radius: Tokens.rounding.extraLarge
        color: Colours.tPalette.m3surfaceContainerHigh

        Calendar {
            id: calendar

            anchors.left: parent.left
            anchors.right: parent.right
            screenState: root.screenState
            scrollable: true
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        Layout.preferredHeight: Timers.enabled ? implicitHeight : 0
        opacity: Timers.enabled ? 1 : 0
        clip: true
        spacing: Tokens.spacing.small
        enabled: Timers.enabled

        Behavior on Layout.preferredHeight {
            Anim {
                type: Anim.DefaultEffects
            }
        }

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }

        StyledText {
            text: Tr.tr("Timers")
            font: Tokens.font.title.small
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.extraSmall

            Repeater {
                model: [
                    GlobalConfig.addons.timers.presetMins0,
                    GlobalConfig.addons.timers.presetMins1,
                    GlobalConfig.addons.timers.presetMins2,
                    GlobalConfig.addons.timers.presetMins3
                ]

                StyledRect {
                    id: preset

                    required property int modelData

                    Layout.fillWidth: true
                    implicitHeight: presetLabel.implicitHeight + Tokens.padding.small * 2
                    radius: Tokens.rounding.full
                    color: Colours.layer(Colours.palette.m3surfaceContainerHighest, 2)

                    StateLayer {
                        radius: parent.radius
                        onClicked: Timers.addMinutes(preset.modelData, "")
                    }

                    StyledText {
                        id: presetLabel

                        anchors.centerIn: parent
                        text: Tr.trN("%n min", "%n mins", preset.modelData)
                        font: Tokens.font.label.small
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            StyledSpinBox {
                id: customMins

                Layout.fillWidth: true
                from: 1
                to: 180
                value: 30
                editable: true
                // Show unit in the field (same msgid as preset chips)
                textFromValue: (value, locale) => Tr.trN("%n min", "%n mins", Math.round(value))
                valueFromText: (text, locale) => {
                    const m = String(text).match(/-?\d+/);
                    return m ? Number(m[0]) : Number.NaN;
                }
                validator: RegularExpressionValidator {
                    // Allow optional "min"/"mins" while editing
                    regularExpression: /^\s*\d{0,3}\s*[a-zA-Z.]*\s*$/
                }

                Component.onCompleted: {
                    if (contentItem)
                        contentItem.implicitWidth = 96;
                }

                Keys.onReturnPressed: root.addCustomTimer()
                Keys.onEnterPressed: root.addCustomTimer()

                Connections {
                    target: customMins.contentItem

                    function onAccepted(): void {
                        root.addCustomTimer();
                    }
                }
            }

            IconButton {
                // Rounded square matching the manual minutes spinner height (not a FAB circle)
                isRound: false
                defaultRadius: Tokens.rounding.medium
                Layout.preferredHeight: customMins.implicitHeight
                Layout.preferredWidth: customMins.implicitHeight
                implicitHeight: customMins.implicitHeight
                implicitWidth: customMins.implicitHeight
                icon: "add"
                type: IconButton.Tonal
                onClicked: root.addCustomTimer()
            }
        }

        StyledText {
            visible: Timers.timers.length === 0
            Layout.fillWidth: true
            text: Tr.tr("No active timers")
            color: Colours.palette.m3outline
            font: Tokens.font.body.small
        }

        Repeater {
            model: Timers.timers

            // ClipRect (RoundedMask) — Rectangle.clip does not honour radius, so a
            // thin remaining fill would otherwise poke past the pill corners.
            ClipRect {
                id: timerRow

                required property var modelData
                // Local clock — don't drive the fill from Timers list churn.
                property int clock: 0
                readonly property real remainingMs: {
                    clock;
                    return Math.max(0, (Number(modelData.endAt) || 0) - Date.now());
                }
                readonly property real progress: {
                    const d = Number(modelData.durationMs) || 0;
                    if (d <= 0)
                        return 0;
                    return Math.max(0, Math.min(1, remainingMs / d));
                }

                Layout.fillWidth: true
                implicitHeight: timerInner.implicitHeight + Tokens.padding.small * 2
                radius: Tokens.rounding.large
                color: Colours.layer(Colours.palette.m3surfaceContainerHighest, 2)

                Timer {
                    interval: 50
                    // Only while the row is on screen and the timer still has time left
                    running: timerRow.visible && timerRow.remainingMs > 0
                    repeat: true
                    onTriggered: timerRow.clock++
                }

                // Remaining fill from the left; parent mask keeps corners clean when thin
                StyledRect {
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    width: parent.width * timerRow.progress
                    visible: width >= 1
                    topRightRadius: Math.min(timerRow.radius, height / 2)
                    bottomRightRadius: topRightRadius
                    color: Colours.palette.m3secondaryContainer
                }

                RowLayout {
                    id: timerInner

                    anchors.fill: parent
                    anchors.margins: Tokens.padding.small
                    spacing: Tokens.spacing.small

                    MaterialIcon {
                        text: "timer"
                        color: Colours.palette.m3secondary
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        StyledText {
                            Layout.fillWidth: true
                            text: timerRow.modelData.label
                            elide: Text.ElideRight
                            font: Tokens.font.label.medium
                        }

                        StyledText {
                            text: Timers.formatRemaining(timerRow.remainingMs)
                            color: Colours.palette.m3onSurfaceVariant
                            font: Tokens.font.mono.small
                        }
                    }

                    IconButton {
                        isRound: true
                        icon: "close"
                        type: IconButton.Text
                        onClicked: Timers.cancel(timerRow.modelData.id)
                    }
                }
            }
        }
    }
}
