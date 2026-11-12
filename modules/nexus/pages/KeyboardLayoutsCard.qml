pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Sylphrena.Config
import Sylphrena.I18n
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common

// Nexus → Language & region → Keyboard: the layouts (first = default), adding one by searching, and the shortcut
// that switches between them. Until something is changed here they are the ones in use (the system's).
ColumnLayout {
    id: root

    readonly property var entries: Hypr.shownKeyboardEntries()
    readonly property bool own: Hypr.keyboardEntries().length > 0
    readonly property var results: {
        const q = search.text.trim().toLowerCase();
        if (q.length < 2)
            return [];
        const taken = new Set(root.entries);
        return Hypr.xkbLayouts.filter(k => {
            const id = k.variant ? `${k.layout}:${k.variant}` : k.layout;
            return !taken.has(id) && (k.name.toLowerCase().includes(q) || k.layout === q);
        }).slice(0, 8);
    }

    function setEntries(list: var): void {
        Hypr.setKeyboardEntries(list);
    }

    Layout.fillWidth: true
    spacing: Tokens.spacing.extraSmall / 2

    ConnectedRect {
        Layout.fillWidth: true
        first: true
        last: root.entries.length < 2
        implicitHeight: col.implicitHeight + Tokens.padding.medium * 2

        ColumnLayout {
            id: col

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
                    text: "keyboard"
                    color: Colours.palette.m3onSurfaceVariant
                    fontStyle: Tokens.font.icon.medium
                    fill: 1
                    Layout.alignment: Qt.AlignVCenter
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    StyledText {
                        Layout.fillWidth: true
                        text: Tr.tr("Keyboard layouts")
                        font: Tokens.font.body.small
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: root.own ? Tr.tr("The first one is used when the session starts; switch from the bar or with the shortcut below") : Tr.tr("The ones of the system. Changing anything here makes Sylphrena keep them")
                        color: Colours.palette.m3outline
                        font: Tokens.font.label.small
                        wrapMode: Text.WordWrap
                    }
                }
            }

            Repeater {
                model: root.entries

                StyledRect {
                    id: layoutRow

                    required property string modelData
                    required property int index

                    Layout.fillWidth: true
                    implicitHeight: rowInner.implicitHeight + Tokens.padding.small * 2
                    radius: Tokens.rounding.medium
                    color: Colours.layer(Colours.palette.m3surfaceContainerHighest, 2)

                    RowLayout {
                        id: rowInner

                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: Tokens.padding.medium
                        anchors.rightMargin: Tokens.padding.small
                        spacing: Tokens.spacing.small

                        StyledText {
                            text: layoutRow.modelData.split(":")[0].toUpperCase()
                            color: Colours.palette.m3primary
                            font: Tokens.font.label.medium
                            Layout.preferredWidth: Tokens.padding.large * 2
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: Hypr.keyboardName(layoutRow.modelData)
                            font: Tokens.font.body.small
                            elide: Text.ElideRight
                        }

                        StyledRect {
                            visible: layoutRow.index === 0 && root.entries.length > 1
                            implicitWidth: mainLabel.implicitWidth + Tokens.padding.medium * 2
                            implicitHeight: mainLabel.implicitHeight + Tokens.padding.extraSmall * 2
                            radius: Tokens.rounding.full
                            color: Colours.palette.m3secondaryContainer

                            StyledText {
                                id: mainLabel

                                anchors.centerIn: parent
                                text: Tr.tr("Default")
                                color: Colours.palette.m3onSecondaryContainer
                                font: Tokens.font.label.small
                            }
                        }

                        IconButton {
                            visible: layoutRow.index > 0
                            icon: "vertical_align_top"
                            type: IconButton.Text
                            implicitWidth: implicitHeight
                            onClicked: {
                                const list = root.entries.slice();
                                list.splice(layoutRow.index, 1);
                                list.unshift(layoutRow.modelData);
                                root.setEntries(list);
                            }
                        }

                        IconButton {
                            enabled: root.entries.length > 1
                            opacity: enabled ? 1 : 0.38
                            icon: "close"
                            type: IconButton.Text
                            implicitWidth: implicitHeight
                            onClicked: root.setEntries(root.entries.filter((_, i) => i !== layoutRow.index))
                        }
                    }
                }
            }

            StyledTextField {
                id: search

                Layout.fillWidth: true
                visible: root.entries.length < 4
                leadingIcon: "add"
                placeholderText: Tr.tr("Add a layout: search by language or code")
                inputMethodHints: Qt.ImhNoPredictiveText
            }

            StyledText {
                Layout.fillWidth: true
                visible: root.entries.length >= 4
                text: Tr.tr("Up to four layouts at a time")
                color: Colours.palette.m3outline
                font: Tokens.font.label.small
            }

            StyledText {
                Layout.fillWidth: true
                visible: search.text.trim().length >= 2 && root.results.length === 0
                text: Tr.tr("No layouts found")
                color: Colours.palette.m3outline
                font: Tokens.font.label.small
            }

            Repeater {
                model: root.results

                StyledRect {
                    id: resultRow

                    required property var modelData

                    Layout.fillWidth: true
                    implicitHeight: resultInner.implicitHeight + Tokens.padding.small * 2
                    radius: Tokens.rounding.medium
                    color: Colours.layer(Colours.palette.m3surfaceContainerHighest, 2)

                    StateLayer {
                        radius: parent.radius
                        onClicked: {
                            const id = resultRow.modelData.variant ? `${resultRow.modelData.layout}:${resultRow.modelData.variant}` : resultRow.modelData.layout;
                            root.setEntries([...root.entries, id]);
                            search.text = "";
                        }
                    }

                    RowLayout {
                        id: resultInner

                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: Tokens.padding.medium
                        anchors.rightMargin: Tokens.padding.medium
                        spacing: Tokens.spacing.small

                        StyledText {
                            text: resultRow.modelData.layout.toUpperCase()
                            color: Colours.palette.m3primary
                            font: Tokens.font.label.medium
                            Layout.preferredWidth: Tokens.padding.large * 2
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: resultRow.modelData.name
                            font: Tokens.font.body.small
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }
    }

    SelectRow {
        visible: root.entries.length > 1
        last: true
        label: Tr.tr("Switch layout")
        subtext: Tr.tr("Keys that change to the next layout")
        menuOnTop: true
        active: switchItems.instances.find(i => i.modelData === (GlobalConfig.general.keyboardSwitch ?? "")) ?? null
        fallbackText: Hypr.keyboardSwitchLabel(GlobalConfig.general.keyboardSwitch ?? "")
        onSelected: item => {
            if (!root.own)
                root.setEntries(root.entries);
            GlobalConfig.general.keyboardSwitch = item.modelData;
        }

        menuItems: switchItems.instances

        Variants {
            id: switchItems

            model: ["", "grp:alt_shift_toggle", "grp:ctrl_shift_toggle", "grp:caps_toggle"]

            MenuItem {
                required property string modelData

                text: Hypr.keyboardSwitchLabel(modelData)
            }
        }
    }
}
