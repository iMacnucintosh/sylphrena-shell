pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Sylphrena.Config
import Sylphrena.I18n
import qs.components
import qs.components.controls
import qs.services

// Checklist page of the dashboard carousel: add, complete and delete tasks; completed ones move to
// a collapsible section at the bottom. The list scrolls vertically.
Item {
    id: root

    required property ScreenState screenState

    implicitHeight: 270

    // The dashboard does not take the keyboard by itself: ask for it while typing (see
    // ScreenState.dashboardTyping → ContentWindow/Interactions), and give it back when done.
    function beginTyping(): void {
        root.screenState.dashboardTyping = true;
        Qt.callLater(() => input.forceActiveFocus());
    }

    function endTyping(): void {
        input.focus = false;
        root.screenState.dashboardTyping = false;
    }

    function submit(): void {
        if (!input.text.trim())
            return;
        Tasks.add(input.text);
        input.clear();
        list.contentY = 0;
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Tokens.padding.large
        spacing: Tokens.spacing.small

        // Title + counter
        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            MaterialIcon {
                text: "checklist"
                color: Colours.palette.m3primary
            }

            StyledText {
                Layout.fillWidth: true
                text: Tr.tr("Tasks")
                font: Tokens.font.title.medium
                elide: Text.ElideRight
            }

            StyledText {
                text: Tasks.pending.length > 0 ? Tr.trN("%n pending", "%n pending", Tasks.pending.length) : ""
                color: Colours.palette.m3outline
                font: Tokens.font.label.small
            }
        }

        // New task
        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            TextFieldBase {
                id: input

                Layout.fillWidth: true
                leftPadding: Tokens.padding.large
                rightPadding: Tokens.padding.large
                topPadding: Tokens.padding.medium
                bottomPadding: Tokens.padding.medium
                maximumLength: 500
                // Placeholder is drawn below (TextFieldBase leaves it to the field)
                onAccepted: root.submit()
                Keys.onEscapePressed: root.endTyping()

                background: StyledRect {
                    radius: Tokens.rounding.small
                    color: Colours.palette.m3surfaceContainerHigh
                    border.width: input.activeFocus ? 2 : 0
                    border.color: Colours.palette.m3primary

                    StateLayer {
                        cursorShape: Qt.IBeamCursor
                        disabled: input.activeFocus
                        onClicked: root.beginTyping()
                    }
                }

                StyledText {
                    anchors.left: parent.left
                    anchors.leftMargin: input.leftPadding
                    anchors.verticalCenter: parent.verticalCenter
                    visible: !input.text && !input.preeditText
                    text: Tr.tr("New task")
                    color: Colours.palette.m3onSurfaceVariant
                    font: input.font
                }
            }

            IconButton {
                icon: "add"
                type: IconButton.Tonal
                isRound: false
                // Same height as the input, and square
                Layout.preferredHeight: input.height
                Layout.preferredWidth: input.height
                enabled: input.text.trim().length > 0
                opacity: enabled ? 1 : 0.5
                onClicked: root.submit()
            }
        }

        // List
        Flickable {
            id: list

            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentWidth: width
            contentHeight: listCol.implicitHeight
            boundsBehavior: Flickable.StopAtBounds

            StyledScrollBar.vertical: StyledScrollBar {
                flickable: list
            }

            ColumnLayout {
                id: listCol

                width: list.width
                spacing: 2

                // Empty state
                StyledText {
                    Layout.fillWidth: true
                    Layout.topMargin: Tokens.padding.large
                    visible: Tasks.items.length === 0
                    horizontalAlignment: Text.AlignHCenter
                    text: Tr.tr("Nothing to do")
                    color: Colours.palette.m3outline
                }

                Repeater {
                    model: Tasks.pending

                    delegate: TaskRow {}
                }

                // Completed section header (collapsible)
                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: Tokens.spacing.small
                    visible: Tasks.done.length > 0
                    spacing: Tokens.spacing.small

                    StyledRect {
                        Layout.fillWidth: true
                        implicitHeight: doneHeader.implicitHeight + Tokens.padding.small * 2
                        radius: Tokens.rounding.full
                        color: "transparent"

                        StateLayer {
                            radius: Tokens.rounding.full
                            onClicked: Tasks.setDoneCollapsed(!Tasks.doneCollapsed)
                        }

                        RowLayout {
                            id: doneHeader

                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: Tokens.padding.small
                            spacing: Tokens.spacing.small

                            MaterialIcon {
                                text: "expand_more"
                                color: Colours.palette.m3onSurfaceVariant
                                rotation: Tasks.doneCollapsed ? -90 : 0

                                Behavior on rotation {
                                    Anim {
                                        type: Anim.FastSpatial
                                    }
                                }
                            }

                            StyledText {
                                text: Tr.tr("Completed (%1)").arg(Tasks.done.length)
                                color: Colours.palette.m3onSurfaceVariant
                                font: Tokens.font.label.medium
                            }
                        }
                    }

                    IconButton {
                        icon: "delete_sweep"
                        type: IconButton.Text
                        isRound: true
                        onClicked: Tasks.clearDone()
                    }
                }

                Repeater {
                    model: Tasks.doneCollapsed ? [] : Tasks.done

                    delegate: TaskRow {}
                }
            }
        }
    }

    component TaskRow: Item {
        id: row

        required property var modelData

        Layout.fillWidth: true
        implicitHeight: Math.max(rowText.implicitHeight, 24) + Tokens.padding.small * 2

        HoverHandler {
            id: rowHover
        }

        // Check circle
        Item {
            id: check

            anchors.left: parent.left
            anchors.leftMargin: Tokens.padding.small
            anchors.verticalCenter: parent.verticalCenter
            width: 22
            height: 22

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: row.modelData.done ? Colours.palette.m3primary : "transparent"
                border.width: row.modelData.done ? 0 : 2
                border.color: Colours.palette.m3outline
            }

            MaterialIcon {
                anchors.centerIn: parent
                visible: row.modelData.done
                text: "check"
                color: Colours.palette.m3onPrimary
                fontStyle: Tokens.font.icon.builders.small.scale(0.8).build()
            }

            MouseArea {
                anchors.fill: parent
                anchors.margins: -6
                cursorShape: Qt.PointingHandCursor
                onClicked: Tasks.toggle(row.modelData.id)
            }
        }

        StyledText {
            id: rowText

            anchors.left: check.right
            anchors.leftMargin: Tokens.spacing.medium
            anchors.right: del.left
            anchors.rightMargin: Tokens.spacing.small
            anchors.verticalCenter: parent.verticalCenter
            text: row.modelData.text
            elide: Text.ElideRight
            maximumLineCount: 2
            wrapMode: Text.Wrap
            color: row.modelData.done ? Colours.palette.m3outline : Colours.palette.m3onSurface
            font.strikeout: row.modelData.done
        }

        IconButton {
            id: del

            anchors.right: parent.right
            anchors.rightMargin: Tokens.padding.small
            anchors.verticalCenter: parent.verticalCenter
            icon: "close"
            type: IconButton.Text
            isRound: true
            opacity: rowHover.hovered ? 1 : 0
            onClicked: Tasks.remove(row.modelData.id)

            Behavior on opacity {
                Anim {
                    type: Anim.StandardSmall
                }
            }
        }
    }
}
