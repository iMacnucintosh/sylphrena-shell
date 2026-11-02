import QtQuick
import QtQuick.Layouts
import Quickshell
import M3Shapes
import Sylphrena
import Sylphrena.Config
import Sylphrena.I18n
import qs.components
import qs.components.widgets
import qs.services

// Content card inside the shell border lobe (PanelBg) — same role as Notification.qml.
StyledRect {
    id: root

    required property Toast modelData
    readonly property bool hasImage: !!(modelData?.image)
    // Soft/round masks that read well as a tiny cover (skip arrows/triangles/etc.).
    readonly property list<int> coverShapes: [
        MaterialShape.Cookie4Sided,
        MaterialShape.Cookie6Sided,
        MaterialShape.Cookie7Sided,
        MaterialShape.Cookie9Sided,
        MaterialShape.Cookie12Sided,
        MaterialShape.SoftBurst,
        MaterialShape.Sunny,
        MaterialShape.VerySunny,
        MaterialShape.Pentagon,
        MaterialShape.Gem,
        MaterialShape.Ghostish,
        MaterialShape.Clover4Leaf,
        MaterialShape.Pill
    ]
    property int coverShape: MaterialShape.Cookie12Sided

    implicitHeight: layout.implicitHeight + Tokens.padding.large

    x: implicitWidth
    Component.onCompleted: {
        const pool = root.coverShapes;
        if (pool.length > 0)
            coverShape = pool[Math.floor(Math.random() * pool.length)];
        x = 0;
        modelData.lock(this);
    }
    Component.onDestruction: modelData?.unlock(this)

    Behavior on x {
        Anim {
            easing: Tokens.anim.emphasizedDecel
        }
    }

    radius: Tokens.rounding.large
    color: {
        if (root.modelData?.type === Toast.Success)
            return Colours.palette.m3successContainer;
        if (root.modelData?.type === Toast.Warning)
            return Colours.palette.m3secondary;
        if (root.modelData?.type === Toast.Error)
            return Colours.palette.m3errorContainer;
        return Colours.tPalette.m3surfaceContainer;
    }

    RowLayout {
        id: layout

        anchors.fill: parent
        anchors.margins: Tokens.padding.small
        anchors.leftMargin: Tokens.padding.medium
        anchors.rightMargin: Tokens.padding.medium
        spacing: Tokens.spacing.medium

        // Now playing: same rotating cookie CoverArt as dashboard media (no progress arc —
        // the toast only appears at track start).
        CoverArt {
            visible: root.hasImage
            implicitWidth: visible ? 88 : 0
            implicitHeight: visible ? 88 : 0
            Layout.preferredWidth: implicitWidth
            Layout.preferredHeight: implicitHeight
            Layout.alignment: Qt.AlignVCenter
            source: root.modelData?.image ?? ""
            shapeType: root.coverShape
        }

        StyledRect {
            id: glyph

            visible: !root.hasImage
            radius: Tokens.rounding.large
            color: {
                if (root.modelData?.type === Toast.Success)
                    return Colours.palette.m3success;
                if (root.modelData?.type === Toast.Warning)
                    return Colours.palette.m3secondaryContainer;
                if (root.modelData?.type === Toast.Error)
                    return Colours.palette.m3error;
                return Colours.palette.m3surfaceContainerHigh;
            }

            implicitWidth: visible ? implicitHeight : 0
            implicitHeight: visible ? icon.implicitHeight + Tokens.padding.large : 0
            Layout.preferredWidth: implicitWidth
            Layout.preferredHeight: implicitHeight
            Layout.alignment: Qt.AlignVCenter

            MaterialIcon {
                id: icon

                anchors.centerIn: parent
                text: root.modelData?.icon ?? ""
                color: {
                    if (root.modelData?.type === Toast.Success)
                        return Colours.palette.m3onSuccess;
                    if (root.modelData?.type === Toast.Warning)
                        return Colours.palette.m3onSecondaryContainer;
                    if (root.modelData?.type === Toast.Error)
                        return Colours.palette.m3onError;
                    return Colours.palette.m3onSurfaceVariant;
                }
                fontStyle: Tokens.font.icon.builders.large.scale(1.2).build()
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                Layout.fillWidth: true
                text: Tr.trMarked(root.modelData?.title ?? "")
                color: {
                    if (root.modelData?.type === Toast.Success)
                        return Colours.palette.m3onSuccessContainer;
                    if (root.modelData?.type === Toast.Warning)
                        return Colours.palette.m3onSecondary;
                    if (root.modelData?.type === Toast.Error)
                        return Colours.palette.m3onErrorContainer;
                    return Colours.palette.m3onSurface;
                }
                font: Tokens.font.title.small
                elide: Text.ElideRight
            }

            StyledText {
                Layout.fillWidth: true
                textFormat: Text.StyledText
                text: Tr.trMarked(root.modelData?.message ?? "")
                color: {
                    if (root.modelData?.type === Toast.Success)
                        return Colours.palette.m3onSuccessContainer;
                    if (root.modelData?.type === Toast.Warning)
                        return Colours.palette.m3onSecondary;
                    if (root.modelData?.type === Toast.Error)
                        return Colours.palette.m3onErrorContainer;
                    return Colours.palette.m3onSurface;
                }
                opacity: 0.8
                wrapMode: Text.WordWrap
            }
        }
    }
}
