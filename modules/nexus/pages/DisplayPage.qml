pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Sylphrena.Config
import Sylphrena.I18n
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus
import qs.modules.nexus.common

// Monitor settings block — lives inline on Connected devices (not a Stack subpage).
ColumnLayout {
    id: root

    required property var nState

    Layout.fillWidth: true
    spacing: Tokens.spacing.extraSmall / 2

    Component.onCompleted: Displays.refresh()

    SectionHeader {
        text: Tr.trCtx("Display", "monitor settings")
    }

    StyledText {
        Layout.fillWidth: true
        visible: Displays.lastError.length > 0
        text: Displays.lastError
        color: Colours.palette.m3error
        font: Tokens.font.body.small
        wrapMode: Text.Wrap
    }

    StyledText {
        Layout.fillWidth: true
        Layout.bottomMargin: Tokens.spacing.small
        visible: Displays.monitors.length === 0 && !Displays.loading && Displays.lastError.length === 0
        text: Tr.tr("No displays detected")
        color: Colours.palette.m3outline
        font: Tokens.font.body.small
    }

    Repeater {
        model: Displays.monitors

        ColumnLayout {
            id: monCol

            required property var modelData
            required property int index

            readonly property var mon: modelData
            readonly property real maxHz: Number(mon.maxHz) || 0
            readonly property real currentHz: {
                const p = Displays.parseMode(mon.mode);
                return p ? p.hz : (Number(mon.refreshRate) || 0);
            }
            readonly property bool connectorLimited: monCol.maxHz > 0 && monCol.maxHz < 200 && monCol.currentHz >= 100
            readonly property int vrrPolicy: Displays.normalizeVrr(Number(mon.vrr) || 0)
            // Stable lists for Variants — calling helpers inline in `model:` rebuilds
            // the array every eval and can leave the SplitButton menu empty/unusable.
            readonly property var resolutions: Displays.resolutionsFromModes(mon.availableModes)
            readonly property string resKey: Displays.resolutionKeyOf(mon.mode)
            readonly property var rates: Displays.ratesForResolution(mon.availableModes, monCol.resKey)

            Layout.fillWidth: true
            Layout.topMargin: index === 0 ? 0 : Tokens.spacing.large - parent.spacing
            spacing: Tokens.spacing.extraSmall / 2

            StyledText {
                Layout.fillWidth: true
                Layout.leftMargin: Tokens.padding.small
                Layout.bottomMargin: Tokens.spacing.extraSmall
                text: (mon.description || mon.name) + (mon.description ? ` · ${mon.name}` : "")
                color: Colours.palette.m3outline
                font: Tokens.font.label.small
                elide: Text.ElideRight
            }

            SelectRow {
                id: resRow

                first: true
                label: Tr.tr("Resolution")
                subtext: Displays.formatResolutionLabel(monCol.resKey)
                active: resItems.instances.find(i => i.modelData === monCol.resKey) ?? null
                fallbackText: Displays.formatResolutionLabel(monCol.resKey)
                onSelected: item => Displays.setResolution(mon.name, item.modelData)

                menuItems: resItems.instances

                Variants {
                    id: resItems

                    model: monCol.resolutions

                    MenuItem {
                        required property string modelData

                        text: Displays.formatResolutionLabel(modelData)
                    }
                }
            }

            SelectRow {
                id: rateRow

                label: Tr.tr("Refresh rate")
                subtext: Displays.formatRateLabel(mon.mode)
                // Short list (same resolution only) so the menu stays inside Nexus.
                active: rateItems.instances.find(i => Displays.modeForHypr(i.modelData) === Displays.modeForHypr(mon.mode)) ?? null
                fallbackText: Displays.formatRateLabel(mon.mode)
                onSelected: item => Displays.setMode(mon.name, item.modelData)

                menuItems: rateItems.instances

                Variants {
                    id: rateItems

                    model: monCol.rates

                    MenuItem {
                        required property string modelData

                        text: Displays.formatRateLabel(modelData)
                    }
                }
            }

            SelectRow {
                id: scaleRow

                label: Tr.tr("Scale")
                subtext: Tr.tr("%1%").arg(Math.round((Number(mon.scale) || 1) * 100))
                active: scaleItems.instances.find(i => Math.abs(i.modelData - (Number(mon.scale) || 1)) < 0.001) ?? null
                fallbackText: Tr.tr("%1%").arg(Math.round((Number(mon.scale) || 1) * 100))
                onSelected: item => Displays.setScale(mon.name, item.modelData)

                menuItems: scaleItems.instances

                Variants {
                    id: scaleItems

                    model: Displays.scaleOptions

                    MenuItem {
                        required property real modelData

                        text: Tr.tr("%1%").arg(Math.round(modelData * 100))
                    }
                }
            }

            SelectRow {
                id: vrrRow

                last: true
                label: Tr.tr("Adaptive Sync")
                subtext: Displays.vrrLabel(monCol.vrrPolicy)
                active: {
                    if (monCol.vrrPolicy === 1)
                        return vrrAlways;
                    if (monCol.vrrPolicy === 2)
                        return vrrAuto;
                    return vrrNever;
                }
                fallbackText: Displays.vrrLabel(monCol.vrrPolicy)
                onSelected: item => Displays.setVrr(mon.name, item.modelData)

                // Plasma order: Never → Automatic → Always
                menuItems: [vrrNever, vrrAuto, vrrAlways]

                MenuItem {
                    id: vrrNever

                    text: Tr.tr("Never")
                    property int modelData: 0
                }

                MenuItem {
                    id: vrrAuto

                    text: Tr.tr("Automatic")
                    property int modelData: 2
                }

                MenuItem {
                    id: vrrAlways

                    text: Tr.tr("Always")
                    property int modelData: 1
                }
            }

            StyledText {
                Layout.fillWidth: true
                Layout.leftMargin: Tokens.padding.small
                text: Displays.vrrHint(monCol.vrrPolicy)
                color: Colours.palette.m3outline
                font: Tokens.font.label.small
                wrapMode: Text.Wrap
            }

            StyledText {
                Layout.fillWidth: true
                Layout.leftMargin: Tokens.padding.small
                visible: monCol.vrrPolicy !== 0
                text: mon.vrrActive ? Tr.tr("Currently active on this output") : Tr.tr("Currently inactive on this output")
                color: Colours.palette.m3outline
                font: Tokens.font.label.small
                wrapMode: Text.Wrap
            }

            StyledText {
                Layout.fillWidth: true
                Layout.topMargin: Tokens.spacing.small
                Layout.leftMargin: Tokens.padding.small
                visible: monCol.connectorLimited
                text: Tr.tr("This connection tops out at %1 Hz. The panel may support a higher rate over DisplayPort.").arg(Math.round(monCol.maxHz))
                color: Colours.palette.m3outline
                font: Tokens.font.label.small
                wrapMode: Text.Wrap
            }
        }
    }

    NavRow {
        Layout.topMargin: Tokens.spacing.large - parent.spacing
        first: true
        last: true
        icon: "crop_free"
        text: Tr.tr("Compact layout")
        subtext: Tr.tr("Session toggle for zero gaps/rounding lives in Panels → Utilities")
        onClicked: root.nState.currentPageIdx = PageRegistry.idxOf("panels")
    }
}
