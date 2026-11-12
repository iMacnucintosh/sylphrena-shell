pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Sylphrena.Config
import Sylphrena.I18n
import qs.components
import qs.components.controls
import qs.components.containers
import qs.components.effects
import qs.services

StyledWindow {
    id: win

    readonly property ShellScreen targetScreen: {
        const screens = Screens.screens;
        for (let i = 0; i < screens.length; i++) {
            const s = screens[i];
            if (Clipboard.cursorX >= s.x && Clipboard.cursorX < s.x + s.width && Clipboard.cursorY >= s.y && Clipboard.cursorY < s.y + s.height)
                return s;
        }
        return screens[0] ?? null;
    }

    screen: targetScreen
    name: "clipboard"
    color: "transparent"
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true

    onTargetScreenChanged: {
        if (targetScreen)
            Qt.callLater(() => search.forceActiveFocus());
    }

    Component.onCompleted: Qt.callLater(() => search.forceActiveFocus())

    // Image preview that unfolds from the thumbnail: the row asks for it (hover, or keyboard selection)
    // and it appears after a short pause so sweeping over the list does not open one per row.
    property Item previewWanted: null
    property bool keyboardNav: false

    function previewRequest(leading: Item): void {
        previewWanted = leading;
        previewDelay.restart();
    }

    function previewRelease(leading: Item): void {
        if (previewWanted !== leading)
            return;
        previewWanted = null;
        previewDelay.stop();
        preview.close();
    }

    Timer {
        id: previewDelay

        interval: 300
        onTriggered: {
            if (win.previewWanted)
                preview.open(win.previewWanted);
        }
    }

    Keys.onEscapePressed: Clipboard.close()
    Keys.onUpPressed: {
        keyboardNav = true;
        Clipboard.moveSelection(-1);
    }
    Keys.onDownPressed: {
        keyboardNav = true;
        Clipboard.moveSelection(1);
    }
    Keys.onReturnPressed: Clipboard.activateCurrent()
    Keys.onEnterPressed: Clipboard.activateCurrent()
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Delete || (event.modifiers & Qt.ControlModifier && event.key === Qt.Key_D)) {
            const item = Clipboard.flatItems[Clipboard.currentIndex];
            if (item)
                Clipboard.deleteEntry(item);
            event.accepted = true;
        }
    }

    // Click outside to dismiss
    MouseArea {
        anchors.fill: parent
        onClicked: event => {
            const p = mapToItem(card, event.x, event.y);
            if (p.x < 0 || p.y < 0 || p.x > card.width || p.y > card.height)
                Clipboard.close();
        }
    }

    Elevation {
        id: card

        readonly property real localX: Clipboard.cursorX - (win.screen?.x ?? 0)
        readonly property real localY: Clipboard.cursorY - (win.screen?.y ?? 0)
        readonly property real margin: Tokens.padding.large
        readonly property real maxW: Math.min(520, (win.screen?.width ?? 520) - margin * 2)
        readonly property real maxH: Math.min(520, (win.screen?.height ?? 520) - margin * 2)

        x: Math.min(Math.max(margin, localX), (win.screen?.width ?? width) - width - margin)
        y: Math.min(Math.max(margin, localY), (win.screen?.height ?? height) - height - margin)
        width: maxW
        height: Math.min(maxH, col.implicitHeight + Tokens.padding.large * 2)
        radius: Tokens.rounding.extraLarge
        level: 3

        StyledRect {
            id: panel

            anchors.fill: parent
            radius: parent.radius
            color: Colours.tPalette.m3surface
            clip: true

            ColumnLayout {
                id: col

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Tokens.padding.large
                spacing: Tokens.spacing.small

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.small

                    MaterialIcon {
                        text: "content_paste"
                        color: Colours.palette.m3primary
                        fontStyle: Tokens.font.icon.large
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: Tr.tr("Clipboard")
                        font: Tokens.font.title.small
                        color: Colours.palette.m3onSurface
                    }

                    IconButton {
                        icon: "delete_sweep"
                        type: IconButton.Text
                        onClicked: Clipboard.clearHistory()
                    }

                    IconButton {
                        icon: "close"
                        type: IconButton.Text
                        onClicked: Clipboard.close()
                    }
                }

                SearchBar {
                    id: search

                    Layout.fillWidth: true
                    placeholderText: Tr.tr("Search clipboard…")
                    text: Clipboard.search
                    onTextChanged: {
                        Clipboard.search = text;
                        Clipboard.currentIndex = 0;
                    }
                    onAccepted: Clipboard.activateCurrent()

                    Keys.onUpPressed: Clipboard.moveSelection(-1)
                    Keys.onDownPressed: Clipboard.moveSelection(1)
                    Keys.onEscapePressed: Clipboard.close()
                }

                StyledText {
                    visible: Clipboard.flatItems.length === 0
                    Layout.fillWidth: true
                    Layout.topMargin: Tokens.padding.medium
                    Layout.bottomMargin: Tokens.padding.medium
                    horizontalAlignment: Text.AlignHCenter
                    text: Clipboard.search.length ? Tr.tr("No matches") : Tr.tr("Clipboard is empty")
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.body.medium
                }

                ListView {
                    id: list

                    visible: Clipboard.flatItems.length > 0
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.min(contentHeight, 360)
                    clip: true
                    model: Clipboard.flatItems
                    currentIndex: Clipboard.currentIndex
                    spacing: Tokens.spacing.extraSmall / 2
                    boundsBehavior: Flickable.StopAtBounds

                    onCurrentIndexChanged: {
                        if (currentIndex !== Clipboard.currentIndex)
                            Clipboard.currentIndex = currentIndex;
                        positionViewAtIndex(currentIndex, ListView.Contain);
                    }

                    Connections {
                        target: Clipboard
                        function onCurrentIndexChanged(): void {
                            list.currentIndex = Clipboard.currentIndex;
                        }
                    }

                    delegate: Item {
                        id: row

                        required property var modelData
                        required property int index

                        readonly property bool isFav: modelData.section === "favorite" || Clipboard.isFavorite(modelData)
                        readonly property bool selected: index === Clipboard.currentIndex
                        readonly property bool hovered: rowLayer.containsMouse
                        readonly property bool wantsPreview: leading.isImage && leading.thumbReady && (hovered || (selected && win.keyboardNav))

                        onWantsPreviewChanged: {
                            if (wantsPreview)
                                win.previewRequest(leading);
                            else
                                win.previewRelease(leading);
                        }
                        onHoveredChanged: {
                            if (hovered)
                                win.keyboardNav = false;
                        }

                        width: list.width
                        height: Tokens.font.body.small.pointSize + Tokens.padding.large * 2

                        StyledRect {
                            anchors.fill: parent
                            radius: Tokens.rounding.large
                            color: row.selected ? Colours.palette.m3secondaryContainer : "transparent"

                            Behavior on color {
                                Anim {
                                    type: Anim.DefaultEffects
                                }
                            }
                        }

                        // Divider between entries (not under the last one, nor next to the highlighted row)
                        StyledRect {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.leftMargin: Tokens.padding.large
                            anchors.rightMargin: Tokens.padding.large
                            implicitHeight: 1
                            color: Colours.palette.m3outlineVariant
                            opacity: row.index === list.count - 1 || row.selected || row.index + 1 === Clipboard.currentIndex ? 0 : 0.5
                        }

                        StateLayer {
                            id: rowLayer

                            anchors.fill: parent
                            radius: Tokens.rounding.large
                            onClicked: {
                                Clipboard.currentIndex = row.index;
                                Clipboard.select(row.modelData);
                            }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Tokens.padding.medium
                            anchors.rightMargin: Tokens.padding.small
                            spacing: Tokens.spacing.small

                            Item {
                                id: leading

                                readonly property bool isImage: row.modelData.kind === "image"
                                readonly property string thumbPath: Clipboard.thumbPathFor(row.modelData)
                                property bool thumbReady: false

                                Layout.preferredWidth: height
                                Layout.preferredHeight: parent.height * 0.78
                                Layout.alignment: Qt.AlignVCenter

                                function ensureThumb(): void {
                                    if (!isImage || !thumbPath.length) {
                                        thumbReady = false;
                                        return;
                                    }
                                    if (row.modelData.path) {
                                        thumbReady = true;
                                        return;
                                    }
                                    thumbReady = false;
                                    if (!thumbProc.running)
                                        thumbProc.running = true;
                                }

                                Component.onCompleted: ensureThumb()
                                onThumbPathChanged: ensureThumb()

                                Process {
                                    id: thumbProc

                                    command: ["bash", "-c", `mkdir -p \"$1\" && f=\"$2\"; [ -s \"$f\" ] || cliphist decode \"$3\" > \"$f\"`, "_", Clipboard.thumbsDir, leading.thumbPath, String(row.modelData.id || "")]
                                    onExited: code => {
                                        leading.thumbReady = code === 0;
                                    }
                                }

                                ClipRect {
                                    anchors.fill: parent
                                    radius: Tokens.rounding.small
                                    visible: leading.isImage

                                    StyledRect {
                                        anchors.fill: parent
                                        color: Colours.layer(Colours.palette.m3surfaceContainerHighest, 2)
                                    }

                                    Image {
                                        id: thumbImage

                                        anchors.fill: parent
                                        asynchronous: true
                                        cache: true
                                        fillMode: Image.PreserveAspectCrop
                                        // Decode to the on-screen thumb size, not the full
                                        // 1440p file (each history row would otherwise ship
                                        // a multi-megapixel texture into VRAM).
                                        sourceSize: Qt.size(Math.max(1, width), Math.max(1, height))
                                        source: leading.thumbReady && leading.thumbPath.length ? Qt.resolvedUrl(leading.thumbPath) : ""
                                        visible: status === Image.Ready
                                    }

                                    MaterialIcon {
                                        anchors.centerIn: parent
                                        visible: thumbImage.status !== Image.Ready
                                        text: "image"
                                        color: row.selected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurfaceVariant
                                        fontStyle: Tokens.font.icon.small
                                    }
                                }

                                MaterialIcon {
                                    anchors.centerIn: parent
                                    visible: !leading.isImage
                                    text: Clipboard.iconForKind(row.modelData.kind)
                                    color: row.selected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurfaceVariant
                                }
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: row.modelData.label || row.modelData.preview || ""
                                elide: Text.ElideRight
                                maximumLineCount: 1
                                color: row.selected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                                font: Tokens.font.body.small
                            }

                            IconButton {
                                icon: "star"
                                type: IconButton.Text
                                isToggle: true
                                checked: row.isFav
                                implicitWidth: implicitHeight
                                opacity: row.isFav || row.hovered ? 1 : 0
                                visible: opacity > 0
                                enabled: visible
                                // Keep star empty on hover until favourited
                                activeOnColour: Colours.palette.m3primary
                                inactiveOnColour: row.selected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurfaceVariant
                                onClicked: Clipboard.toggleFavorite(row.modelData)

                                Behavior on opacity {
                                    Anim {
                                        type: Anim.DefaultEffects
                                    }
                                }
                            }

                            IconButton {
                                icon: "close"
                                type: IconButton.Text
                                implicitWidth: implicitHeight
                                opacity: row.selected || row.hovered ? 1 : 0.55
                                onClicked: Clipboard.deleteEntry(row.modelData)
                            }
                        }
                    }
                }
            }
        }
    }

    // Big image that unfolds from the hovered thumbnail (non-interactive: clicks and hover go to the list)
    Item {
        id: preview

        readonly property real maxW: 480
        readonly property real maxH: 360

        property Item leading: null
        property real progress: 0
        property real fromX
        property real fromY
        property real fromW: 1
        property real fromH: 1
        property real toX
        property real toY
        property real toW: 1
        property real toH: 1

        function lerp(a: real, b: real): real {
            return a + (b - a) * progress;
        }

        function open(l: Item): void {
            const nw = big.implicitWidth;
            const nh = big.implicitHeight;
            if (!l || nw <= 0 || nh <= 0)
                return; // not decoded yet: big.onStatusChanged opens it when it is
            leading = l;
            const from = l.mapToItem(null, 0, 0);
            fromX = from.x;
            fromY = from.y;
            fromW = l.width;
            fromH = l.height;
            const k = Math.min(1, maxW / nw, maxH / nh);
            // Barely bigger than the thumbnail: nothing to gain from a popup
            if (nw * k < l.width * 1.5 && nh * k < l.height * 1.5)
                return;
            toW = Math.max(l.width, nw * k);
            toH = Math.max(l.height, nh * k);
            const gap = Tokens.padding.medium;
            const sw = win.width;
            // Beside the card, on the side with room; centred on the thumbnail's height
            let x = card.x + card.width + gap;
            if (x + toW > sw - card.margin)
                x = card.x - gap - toW;
            toX = Math.max(card.margin, Math.min(x, sw - toW - card.margin));
            toY = Math.max(card.margin, Math.min(from.y + l.height / 2 - toH / 2, win.height - toH - card.margin));
            progress = 0;
            anim.to = 1;
            anim.restart();
        }

        function close(): void {
            anim.to = 0;
            anim.restart();
        }

        visible: leading !== null && progress > 0.001
        enabled: false
        x: lerp(fromX, toX)
        y: lerp(fromY, toY)
        width: lerp(fromW, toW)
        height: lerp(fromH, toH)

        Anim {
            id: anim

            target: preview
            property: "progress"
            type: Anim.DefaultSpatial
            onFinished: {
                if (preview.progress <= 0.001)
                    preview.leading = null;
            }
        }

        // Decoded in the background while the pause runs, so it is ready when the popup opens
        Image {
            id: big

            visible: false
            asynchronous: true
            cache: false
            onStatusChanged: {
                // Decoded after the pause already ran out: open now if it is still wanted
                if (status === Image.Ready && win.previewWanted && !previewDelay.running && preview.progress < 0.001)
                    preview.open(win.previewWanted);
            }
            source: preview.leading ? Qt.resolvedUrl(preview.leading.thumbPath) : (win.previewWanted ? Qt.resolvedUrl(win.previewWanted.thumbPath) : "")
        }

        Elevation {
            anchors.fill: parent
            radius: Tokens.rounding.large
            level: 3
            opacity: Math.min(1, preview.progress * 3)

            ClipRect {
                anchors.fill: parent
                radius: Tokens.rounding.large

                StyledRect {
                    anchors.fill: parent
                    color: Colours.tPalette.m3surface
                }

                Image {
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectCrop
                    smooth: true
                    mipmap: true
                    source: big.source
                }

                StyledRect {
                    anchors.left: parent.left
                    anchors.bottom: parent.bottom
                    anchors.margins: Tokens.padding.small
                    implicitWidth: dims.implicitWidth + Tokens.padding.medium * 2
                    implicitHeight: dims.implicitHeight + Tokens.padding.extraSmall * 2
                    radius: Tokens.rounding.full
                    color: Qt.alpha(Colours.palette.m3surface, 0.8)
                    opacity: Math.max(0, (preview.progress - 0.7) / 0.3)

                    StyledText {
                        id: dims

                        anchors.centerIn: parent
                        text: `${big.implicitWidth} × ${big.implicitHeight}`
                        color: Colours.palette.m3onSurface
                        font: Tokens.font.label.small
                    }
                }
            }
        }
    }
}
