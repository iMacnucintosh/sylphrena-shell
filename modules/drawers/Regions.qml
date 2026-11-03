pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Sylphrena.Config
import qs.components.controls
import qs.modules.bar as Bar
import qs.modules.launcher.services

Region {
    id: root

    required property Bar.BarWrapper bar
    required property Panels panels
    required property var win

    readonly property real borderThickness: win.contentItem.Config.border.thickness
    readonly property real clampedThickness: win.contentItem.Config.border.clampedThickness

    x: bar.clampedWidth + win.dragMaskPadding
    y: clampedThickness + win.dragMaskPadding
    width: win.width - bar.clampedWidth - clampedThickness - win.dragMaskPadding * 2
    height: win.height - clampedThickness * 2 - win.dragMaskPadding * 2
    intersection: Intersection.Xor

    R {
        panel: root.panels.dashboard
        y: 0
        height: panel.height * (1 - root.panels.dashboard.offsetScale) + root.borderThickness
    }

    R {
        panel: root.panels.launcher
        y: root.win.height - height
        height: panel.height * (1 - root.panels.launcher.offsetScale) + root.borderThickness
    }

    // Desktop edit dialog is centered on the full drawer; without this, clicks pass
    // through the layer mask, clear the focus grab, and dismiss the launcher.
    Region {
        x: root.x
        y: root.y
        width: Apps.editingDesktop ? root.width : 0
        height: Apps.editingDesktop ? root.height : 0
        intersection: Intersection.Subtract
    }

    // Context menus from the bar (e.g. activity pill) open into the passthrough hole;
    // without a subtract region they paint but never receive clicks.
    Region {
        readonly property var m: Menus.current
        readonly property bool open: !!(m && m.expanded)
        // Pad slightly for elevation shadow / rounding.
        readonly property real pad: open ? Tokens.padding.small : 0

        x: open ? m.regionX - pad : 0
        y: open ? m.regionY - pad : 0
        width: open ? m.regionWidth + pad * 2 : 0
        height: open ? m.regionHeight + pad * 2 : 0
        intersection: Intersection.Subtract
    }

    R {
        id: sessionRegion

        panel: root.panels.sessionWrapper
        x: root.win.width - width
        width: panel.width * (1 - root.panels.session.offsetScale) + root.borderThickness + sidebarRegion.width
    }

    R {
        id: sidebarRegion

        panel: root.panels.sidebar
        x: root.win.width - width
        width: panel.width * (1 - root.panels.sidebar.offsetScale) + root.borderThickness
    }

    R {
        panel: root.panels.osdWrapper
        x: root.win.width - width
        width: panel.width * (1 - root.panels.osd.offsetScale) + root.borderThickness + sessionRegion.width
    }

    R {
        panel: root.panels.notifications
        y: 0
        height: panel.height + root.borderThickness
    }

    R {
        panel: root.panels.toasts
        y: root.panels.toasts.atBottom ? panel.y + root.borderThickness : 0
        height: panel.height > 0 ? panel.height + root.borderThickness : 0
    }

    R {
        panel: root.panels.utilities
        y: root.win.height - height
        height: panel.height * (1 - root.panels.utilities.offsetScale) + root.borderThickness
    }

    R {
        panel: root.panels.popoutsWrapper
        width: panel.width * (1 - root.panels.popoutsWrapper.offsetScale)
    }

    component R: Region {
        required property Item panel

        x: panel.x + root.bar.implicitWidth
        y: panel.y + root.borderThickness
        width: panel.width
        height: panel.height
        intersection: Intersection.Subtract
    }
}
