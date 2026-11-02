pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Widgets
import Sylphrena
import Sylphrena.Config
import qs.components
import qs.components.containers
import qs.services

// Same list mechanics as the notification popups (modules/notifications/Content.qml): cards
// slide in/out sideways, siblings shift with move/displaced and the lobe height animates on
// the expressive spatial curve. Fed by Toaster, never by the notification list.
Item {
    id: root

    readonly property int spacing: Tokens.spacing.small
    readonly property int padding: Tokens.padding.large
    readonly property int clampedPadding: CUtils.clamp(padding - Config.border.thickness, 0, padding)
    readonly property bool atBottom: GlobalConfig.utilities.toasts.position === "bottom"
    // Bumped when a card's height settles (text wrap lands after the delegate is counted).
    property int relayout
    readonly property real contentHeight: {
        relayout;
        const count = list.count;
        if (count === 0)
            return 0;

        let height = (count - 1) * spacing;
        for (let i = 0; i < count; i++)
            height += (list.itemAtIndex(i) as ToastWrapper)?.nonAnimHeight ?? 0;
        return height;
    }

    function bumpRelayout(): void {
        relayout++;
    }

    // Pull into the border like notifications so PanelBg joins the shell edge.
    readonly property real edgeOverlap: contentHeight > 0 ? 5 : 0

    function shouldShowToast(toast: Toast): bool {
        if (!Notifs.hasFullscreen())
            return true;
        if (GlobalConfig.utilities.toasts.fullscreen === "all")
            return true;
        if (GlobalConfig.utilities.toasts.fullscreen === "important")
            return toast.type === Toast.Warning || toast.type === Toast.Error;
        return false;
    }

    visible: height > 0
    implicitWidth: Tokens.sizes.notifs.width
    implicitHeight: contentHeight > 0 ? contentHeight + padding + clampedPadding : 0
    // BlobRect/PanelBg reads width/height (not implicit*); keep them in sync.
    width: implicitWidth
    height: implicitHeight

    Behavior on implicitHeight {
        Anim {}
    }

    // Fixed card column pinned right, like the notification cards when the lobe widens.
    ClippingWrapperRectangle {
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.topMargin: root.atBottom ? root.padding : root.clampedPadding
        anchors.bottomMargin: root.atBottom ? root.clampedPadding : root.padding
        anchors.rightMargin: root.clampedPadding
        width: root.implicitWidth - root.padding - root.clampedPadding

        color: "transparent"
        radius: Tokens.rounding.large

        StyledListView {
            id: list

            model: ScriptModel {
                values: {
                    const toasts = [];
                    for (const toast of Toaster.toasts) {
                        if (toast.closed || !root.shouldShowToast(toast))
                            continue;
                        toasts.push(toast);
                        if (toasts.length >= root.Config.utilities.maxToasts)
                            break;
                    }
                    return toasts;
                }
            }

            anchors.fill: parent

            orientation: Qt.Vertical
            // Toaster keeps the newest first: nearest the screen edge the lobe grows from, so
            // the lobe reveals it as it opens (like the notification popups).
            verticalLayoutDirection: root.atBottom ? ListView.BottomToTop : ListView.TopToBottom
            spacing: 0
            interactive: false
            cacheBuffer: (QsWindow.window as QsWindow)?.screen.height ?? 0

            delegate: ToastWrapper {}

            move: Transition {
                Anim {
                    property: "y"
                }
            }

            displaced: Transition {
                Anim {
                    property: "y"
                }
            }
        }
    }

    component ToastWrapper: Item {
        id: wrapper

        required property Toast modelData
        required property int index
        readonly property real nonAnimHeight: toast.implicitHeight
        property int idx

        onIndexChanged: {
            if (index !== -1)
                idx = index;
        }
        // Deferred: itemAtIndex() only returns this delegate once the view has registered it.
        onNonAnimHeightChanged: Qt.callLater(root.bumpRelayout)
        Component.onCompleted: Qt.callLater(root.bumpRelayout)

        implicitWidth: toast.implicitWidth
        implicitHeight: toast.implicitHeight + (idx === 0 ? 0 : root.spacing)

        ListView.onRemove: removeAnim.start()

        SequentialAnimation {
            id: removeAnim

            PropertyAction {
                target: wrapper
                property: "ListView.delayRemove"
                value: true
            }
            PropertyAction {
                target: wrapper
                property: "enabled"
                value: false
            }
            PropertyAction {
                target: wrapper
                property: "implicitHeight"
                value: 0
            }
            PropertyAction {
                target: wrapper
                property: "z"
                value: 1
            }
            Anim {
                target: toast
                property: "x"
                to: root.implicitWidth * 2
                duration: Tokens.anim.durations.normal
                easing: Tokens.anim.emphasized
            }
            PropertyAction {
                target: wrapper
                property: "ListView.delayRemove"
                value: false
            }
        }

        ClipRect {
            anchors.top: parent.top
            anchors.topMargin: !root.atBottom && wrapper.idx !== 0 ? root.spacing : 0

            color: "transparent"
            radius: toast.radius
            implicitWidth: toast.implicitWidth
            implicitHeight: toast.implicitHeight

            ToastItem {
                id: toast

                modelData: wrapper.modelData
                implicitWidth: root.implicitWidth - root.padding - root.clampedPadding

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                    onClicked: toast.modelData.close()
                }
            }
        }
    }

    component Anim: NumberAnimation {
        duration: Tokens.anim.durations.expressiveDefaultSpatial
        easing: Tokens.anim.expressiveDefaultSpatial
    }
}
