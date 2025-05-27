import "root:/widgets"
import "root:/services"
import "root:/config"
import QtQuick
import QtQuick.Effects

StyledRect {
    id: root

    required property list<Workspace> workspaces
    required property Item mask
    required property real maskWidth
    required property real maskHeight
    required property int groupOffset

    readonly property Workspace currentWs: workspaces[Hyprland.activeWsId - 1 - groupOffset] ?? null
    property real leading: currentWs?.y ?? 0
    property real trailing: currentWs?.y ?? 0
    property real currentSize: (currentWs?.size) ?? 0
    property real size: Math.abs(leading - trailing) + currentSize
    property real offset: Math.min(leading, trailing)

    clip: true
    x: 1
    y: offset + 1
    implicitWidth: BarConfig.sizes.innerHeight - 2
    implicitHeight: size - 2
    radius: BarConfig.workspaces.rounded ? Appearance.rounding.full : 0
    color: Colours.palette.m3primary

    StyledRect {
        id: base

        visible: false
        anchors.fill: parent
        color: Colours.palette.m3onPrimary
    }

    MultiEffect {
        source: base
        maskSource: root.mask
        maskEnabled: true
        maskSpreadAtMin: 1
        maskThresholdMin: 0.5

        x: 0
        y: -parent.offset
        implicitWidth: root.maskWidth
        implicitHeight: root.maskHeight

        anchors.horizontalCenter: parent.horizontalCenter
    }

    Behavior on leading {
        enabled: BarConfig.workspaces.activeTrail

        Anim {}
    }

    Behavior on trailing {
        enabled: BarConfig.workspaces.activeTrail

        Anim {
            duration: Appearance.anim.durations.normal * 2
        }
    }

    Behavior on currentSize {
        enabled: BarConfig.workspaces.activeTrail

        Anim {}
    }

    Behavior on offset {
        enabled: !BarConfig.workspaces.activeTrail

        Anim {}
    }

    Behavior on size {
        enabled: !BarConfig.workspaces.activeTrail

        Anim {}
    }

    component Anim: NumberAnimation {
        duration: Appearance.anim.durations.normal
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Appearance.anim.curves.emphasized
    }
}
