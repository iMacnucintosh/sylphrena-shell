pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Sylphrena.Config
import Sylphrena.State
import qs.components.containers
import qs.modules.bar as Bar

Scope {
    id: root

    required property ShellScreen screen
    required property Bar.BarWrapper bar

    // Through the bar: Config needs an item on a screen (this Scope has none)
    readonly property int frameZone: RuntimeState.gameMode ? 0 : root.bar.Config.border.thickness

    ExclusionZone {
        anchors.left: true
        exclusiveZone: root.bar.exclusiveZone
    }

    ExclusionZone {
        anchors.top: true
        exclusiveZone: root.frameZone
    }

    ExclusionZone {
        anchors.right: true
        exclusiveZone: root.frameZone
    }

    ExclusionZone {
        anchors.bottom: true
        exclusiveZone: root.frameZone
    }

    component ExclusionZone: StyledWindow {
        screen: root.screen
        name: "border-exclusion"
        exclusiveZone: contentItem.Config.border.thickness
        mask: Region {}
        implicitWidth: 1
        implicitHeight: 1
    }
}
