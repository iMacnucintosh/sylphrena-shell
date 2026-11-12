pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Sylphrena.Blobs
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

    // Card and image preview are drawn as one shape, like the shell's drawers: the preview grows out of
    // the card's edge with smooth concave corners where they meet.
    Item {
        id: blobLayer

        anchors.fill: parent
        opacity: Colours.tPalette.m3surface.a
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            blurMax: 15
            shadowColor: Qt.alpha(Colours.palette.m3shadow, 0.7)
        }

        BlobGroup {
            id: blobs

            color: Qt.alpha(Colours.tPalette.m3surface, 1)
            smoothing: blobLayer.Tokens.rounding.large
        }

        BlobRect {
            group: blobs
            x: card.x
            y: card.y
            width: card.width
            height: card.height
            radius: card.radius
            deformScale: 0.00001
        }

        BlobRect {
            // How much of it hides under the card, so both always merge
            readonly property real tuck: card.radius
            readonly property real w: preview.lerp(0, preview.contW)

            // Closed: parked inside the card, where it adds nothing to the shape
            readonly property bool shown: preview.visible

            group: blobs
            x: !shown ? card.x + card.radius : preview.side < 0 ? card.x - w : card.x + card.width - tuck
            y: shown ? preview.lerp(preview.fromY, preview.imgY - preview.pad) : card.y + card.height / 2
            width: shown ? w + tuck : 1
            height: shown ? Math.max(1, preview.lerp(preview.fromH, preview.contH)) : 1
            radius: Tokens.rounding.large
            deformScale: 0.00001
        }
    }

    Item {
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

        readonly property real radius: Tokens.rounding.extraLarge

        StyledRect {
            id: panel

            anchors.fill: parent
            radius: parent.radius
            color: "transparent" // the blob layer above draws the surface
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
                        // Over the whole row, its buttons included: a MouseArea loses the hover to the star, which then
                        // hid itself and let the click through to the row (pasting instead of marking a favourite)
                        readonly property bool hovered: rowHover.hovered
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

                        HoverHandler {
                            id: rowHover
                        }

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
                                    // The thumbnail is out of its row while its preview is open
                                    opacity: preview.leading === leading && preview.progress > 0.001 ? 0 : 1

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

    // The hovered thumbnail slides out of its row into a panel that grows from the card's edge (to the left
    // unless there is no room) and becomes the big image. Non-interactive: clicks and hover go to the list.
    Item {
        id: preview

        readonly property real maxW: 480
        readonly property real maxH: 360
        readonly property real pad: Tokens.padding.small

        property Item leading: null
        property real progress: 0
        property int side: -1 // -1: panel on the card's left, 1: on its right
        // thumbnail rect (start) and final image rect, in window coordinates
        property real fromX
        property real fromY
        property real fromW: 1
        property real fromH: 1
        property real imgX
        property real imgY
        property real imgW: 1
        property real imgH: 1

        readonly property real contW: imgW + pad * 2
        readonly property real contH: imgH + pad * 2

        function lerp(a: real, b: real): real {
            return a + (b - a) * progress;
        }

        function open(l: Item): void {
            const nw = big.implicitWidth;
            const nh = big.implicitHeight;
            if (!l || nw <= 0 || nh <= 0)
                return; // not decoded yet: big.onStatusChanged opens it when it is
            const from = l.mapToItem(null, 0, 0);
            const r = Tokens.rounding.large;
            const availH = Math.min(maxH, card.height - r * 2 - pad * 2);
            const k = Math.min(1, maxW / nw, availH / nh);
            // Barely bigger than the thumbnail: nothing to gain from a panel
            if (nw * k < l.width * 1.5 && nh * k < l.height * 1.5)
                return;
            leading = l;
            fromX = from.x;
            fromY = from.y;
            fromW = l.width;
            fromH = l.height;
            const w = Math.max(l.width, nw * k);
            const h = Math.max(l.height, nh * k);
            side = card.x - (w + pad * 2) >= card.margin ? -1 : 1;
            imgW = w;
            imgH = h;
            imgX = side < 0 ? card.x - w - pad : card.x + card.width + pad;
            const top = card.y + r;
            const bottom = card.y + card.height - r - (h + pad * 2);
            const wanted = from.y + l.height / 2 - (h + pad * 2) / 2;
            imgY = Math.max(top, Math.min(wanted, Math.max(top, bottom))) + pad;
            progress = 0;
            anim.to = 1;
            anim.restart();
        }

        function close(): void {
            anim.to = 0;
            anim.restart();
        }

        anchors.fill: parent
        enabled: false
        visible: leading !== null && progress > 0.001

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

        // Decoded in the background while the pause runs, so it is ready when the panel opens
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

        // The thumbnail itself: leaves the row and grows into the panel
        ClipRect {
            x: preview.lerp(preview.fromX, preview.imgX)
            y: preview.lerp(preview.fromY, preview.imgY)
            width: preview.lerp(preview.fromW, preview.imgW)
            height: preview.lerp(preview.fromH, preview.imgH)
            radius: preview.lerp(Tokens.rounding.small, Tokens.rounding.medium)

            Image {
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                smooth: true
                mipmap: true
                source: big.source
            }
        }
    }
}
