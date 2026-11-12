import QtQuick
import QtQuick.Layouts
import Quickshell.Wayland
import Quickshell.Widgets
import Sylphrena.Config
import qs.components
import qs.services
import qs.utils

// A live thumbnail of the window whose app icon is hovered in the bar; a click goes to that window
Item {
    id: root

    required property PopoutState popouts
    readonly property var toplevel: popouts.previewToplevel

    implicitWidth: toplevel ? child.implicitWidth : -Tokens.padding.extraLargeIncreased
    implicitHeight: child.implicitHeight

    Column {
        id: child

        anchors.centerIn: parent
        spacing: Tokens.spacing.medium

        RowLayout {
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: Tokens.spacing.medium

            IconImage {
                asynchronous: true
                Layout.alignment: Qt.AlignVCenter
                implicitSize: details.implicitHeight
                source: Icons.getAppIcon(root.toplevel?.lastIpcObject?.class ?? "", "image-missing")
            }

            ColumnLayout {
                id: details

                spacing: 0
                Layout.fillWidth: true

                StyledText {
                    Layout.fillWidth: true
                    text: root.toplevel?.title ?? ""
                    font: Tokens.font.body.medium
                    elide: Text.ElideRight
                }

                StyledText {
                    Layout.fillWidth: true
                    text: root.toplevel?.lastIpcObject?.class ?? ""
                    color: Colours.palette.m3onSurfaceVariant
                    elide: Text.ElideRight
                }
            }
        }

        ClippingWrapperRectangle {
            color: "transparent"
            radius: Tokens.rounding.medium

            ScreencopyView {
                captureSource: root.toplevel?.wayland ?? null
                live: visible

                constraintSize.width: Tokens.sizes.bar.windowPreviewSize
                constraintSize.height: Tokens.sizes.bar.windowPreviewSize

                StateLayer {
                    anchors.fill: parent
                    radius: Tokens.rounding.medium
                    onClicked: {
                        Hypr.focusToplevel(root.toplevel, false);
                        root.popouts.hasCurrent = false;
                    }
                }
            }
        }
    }
}
