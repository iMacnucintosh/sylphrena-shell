pragma ComponentBehavior: Bound

import "cards"
import QtQuick
import QtQuick.Layouts
import Sylphrena.Config
import qs.components
import qs.modules.bar.popouts as BarPopouts

Item {
    id: root

    required property var props
    required property ScreenState screenState
    required property BarPopouts.Wrapper popouts
    required property matrix4x4 deformMatrix

    readonly property real recordHeight: (record.item as Record)?.implicitHeight ?? 0
    readonly property real recordTargetHeight: (record.item as Record)?.nonAnimHeight ?? 0
    readonly property bool recordVisible: recordHeight > 0.5
    readonly property int enabledCards: (idleInhibit.active ? 1 : 0) + (recordVisible ? 1 : 0) + (toggles.active ? 1 : 0)
    // Gaps are Layout.topMargin (animated with the record card), not ColumnLayout.spacing.
    readonly property real nonAnimHeight: ((idleInhibit.item as IdleInhibit)?.nonAnimHeight ?? 0) + ((record.item as Record)?.nonAnimHeight ?? 0) + ((toggles.item as Toggles)?.implicitHeight ?? 0) + Tokens.spacing.medium * Math.max(0, enabledCards - 1)

    implicitWidth: layout.implicitWidth
    implicitHeight: layout.implicitHeight

    ColumnLayout {
        id: layout

        anchors.fill: parent
        // Per-item topMargin so the record gap collapses with the card instead of snapping off.
        spacing: 0

        Loader {
            id: idleInhibit

            Layout.fillWidth: true
            active: Config.utilities.cards.keepAwake
            visible: active

            sourceComponent: IdleInhibit {
                objectName: "utilitiesKeepAwake"
            }
        }

        Loader {
            id: toggles

            Layout.fillWidth: true
            Layout.topMargin: idleInhibit.active ? Tokens.spacing.medium : 0
            active: Config.utilities.cards.quickToggles
            visible: active

            sourceComponent: Toggles {
                objectName: "utilitiesQuickToggles"

                props: root.props
                screenState: root.screenState
                popouts: root.popouts
            }
        }

        Loader {
            id: record

            Layout.fillWidth: true
            // Target gap from nonAnimHeight so topMargin and card height start/stop together.
            Layout.topMargin: root.recordTargetHeight > 0 && (toggles.active || idleInhibit.active) ? Tokens.spacing.medium : 0
            Layout.preferredHeight: root.recordHeight
            // Keep in the tree at height 0 — hiding would drop spacing in a final snap.
            active: Config.utilities.cards.recorder
            visible: active
            clip: true
            z: 1

            Behavior on Layout.topMargin {
                Anim {
                    type: Anim.Emphasized
                }
            }

            sourceComponent: Record {
                objectName: "utilitiesScreenRecorder"

                props: root.props
                screenState: root.screenState
                embeddedInToggles: Config.utilities.cards.quickToggles
            }
        }
    }

    RecordingDeleteModal {
        props: root.props
        deformMatrix: root.deformMatrix
    }
}
