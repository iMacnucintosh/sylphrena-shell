pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Services.SystemTray
import Sylphrena.Config
import qs.components
import qs.components.effects
import qs.services
import qs.utils

// Mirrors StatusIcons EntryWrapper: hover fills a content-sized cell (vertical pill),
// not the full bar width.
Item {
    id: root

    required property SystemTrayItem modelData
    required property int index
    required property var popouts

    readonly property int iconSize: 20
    // Same pad as StatusIcons EntryWrapper
    readonly property int iconPad: Tokens.padding.extraSmall
    // MaterialIcon cells are taller than wide (font metrics) → vertical pill hover
    readonly property int statusIconH: Math.round(Tokens.font.icon.medium.pixelSize)

    readonly property string trayId: String(modelData.id || "").toLowerCase()
    readonly property string trayIcon: String(modelData.icon || "").toLowerCase()

    readonly property string iconSource: Icons.getTrayIcon(modelData.id, modelData.icon)

    // Near-black tray glyphs (Cursor, Claude, Steam...) vanish on dark bars. Measured from
    // the icon pixels by the probe below; the name list is only a fallback for when the
    // probe cannot read the image.
    property bool darkGlyph: false
    readonly property bool forceLightIcon: darkGlyph || trayId.includes("cursor") || trayId.includes("claude") || trayId.includes("steam") || trayIcon.includes("steam")
    readonly property bool colourise: Config.bar.tray.recolour || forceLightIcon
    readonly property bool menuOpen: popouts?.hasCurrent && popouts?.currentName === `traymenu${index}`
    readonly property bool highlighted: hover.containsMouse || menuOpen

    implicitWidth: iconSize + iconPad * 2
    implicitHeight: Math.max(iconSize, statusIconH) + iconPad * 2

    StyledRect {
        anchors.fill: parent
        radius: Tokens.rounding.full
        color: root.highlighted ? Colours.palette.m3primary : "transparent"
        z: -1

        Behavior on color {
            CAnim {}
        }
    }

    // Invisible 16x16 probe: alpha-weighted mean luminance of the icon. Dark and mostly
    // opaque-ish glyph => needs forcing to a light colour (only while the bar is dark).
    Canvas {
        id: probe

        width: 16
        height: 16
        opacity: 0
        renderTarget: Canvas.Image

        onPaint: {
            const ctx = getContext("2d");
            ctx.clearRect(0, 0, 16, 16);
            ctx.drawImage(root.iconSource, 0, 0, 16, 16);
            const d = ctx.getImageData(0, 0, 16, 16).data;
            let lum = 0, a = 0;
            for (let i = 0; i < d.length; i += 4) {
                lum += (0.2126 * d[i] + 0.7152 * d[i + 1] + 0.0722 * d[i + 2]) * d[i + 3];
                a += d[i + 3];
            }
            // Ignore empty/failed reads; threshold on 0..255 luminance.
            root.darkGlyph = a > 255 * 8 && (lum / a) < 90;
        }
        onImageLoaded: requestPaint()
        Component.onCompleted: loadImage(root.iconSource)

        Connections {
            function onIconSourceChanged() {
                probe.loadImage(root.iconSource);
                probe.requestPaint();
            }

            target: root
        }
    }

    ColouredIcon {
        id: icon

        anchors.centerIn: parent
        implicitSize: root.iconSize
        width: root.iconSize
        height: root.iconSize
        source: root.iconSource
        colour: root.highlighted ? Colours.palette.m3onPrimary : Config.bar.tray.recolour ? Colours.palette.m3secondary : Colours.palette.m3onSurface
        layer.enabled: root.colourise
        asynchronous: true
        mipmap: true
    }

    MouseArea {
        id: hover

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onClicked: event => {
            if (event.button === Qt.LeftButton)
                root.modelData.activate();
            else
                root.modelData.secondaryActivate();
        }
    }
}
