pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Sylphrena.Components
import Sylphrena.Config
import Sylphrena.I18n
import qs.components
import qs.components.controls
import qs.components.misc
import qs.services

StyledRect {
    id: root

    required property var props
    required property ScreenState screenState
    // When true, collapsed quick-access lives in Toggles; this card is expand-only.
    property bool embeddedInToggles: false

    readonly property bool effectivelyExpanded: props.recordingCardExpanded || Recorder.running
    readonly property bool showCollapsedChip: !embeddedInToggles && !effectivelyExpanded
    readonly property real nonAnimHeight: {
        if (embeddedInToggles && !effectivelyExpanded)
            return 0;
        if (showCollapsedChip)
            return collapsedLayout.implicitHeight + collapsedLayout.anchors.margins * 2;
        return expandedLayout.implicitHeight + expandedLayout.anchors.margins * 2;
    }

    implicitHeight: nonAnimHeight

    radius: Tokens.rounding.large
    color: Colours.tPalette.m3surfaceContainer
    clip: true
    // Never toggle visible here — parent Loader clips at height 0 so collapse stays continuous.

    Behavior on implicitHeight {
        Anim {
            type: Anim.Emphasized
        }
    }

    Ref {
        service: Recorder
    }

    // Standalone fallback when the quick-toggles card is disabled.
    Row {
        id: collapsedLayout

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.margins: Tokens.padding.large
        spacing: Math.floor(Tokens.spacing.extraSmall / 2)
        visible: root.showCollapsedChip
        enabled: visible

        readonly property color colour: Colours.palette.m3primary
        readonly property color textColour: Colours.palette.m3onPrimary
        readonly property bool startDisabled: Recorder.running || Recorder.arming
        readonly property real horizontalPadding: Tokens.padding.medium
        readonly property real verticalPadding: Tokens.padding.small

        StyledRect {
            radius: implicitHeight / 2 * Math.min(1, Tokens.rounding.scale)
            topRightRadius: Tokens.rounding.medium / 2
            bottomRightRadius: Tokens.rounding.medium / 2
            color: collapsedLayout.startDisabled ? Qt.alpha(Colours.palette.m3onSurface, 0.1) : collapsedLayout.colour

            implicitWidth: collapsedRow.implicitWidth + collapsedLayout.horizontalPadding * 2
            implicitHeight: expandChip.implicitHeight

            StateLayer {
                topRightRadius: parent.topRightRadius
                bottomRightRadius: parent.bottomRightRadius
                color: collapsedLayout.textColour
                disabled: collapsedLayout.startDisabled
                onClicked: Recorder.start()
            }

            Row {
                id: collapsedRow

                anchors.centerIn: parent
                spacing: Tokens.spacing.small

                MaterialIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: 1
                    text: "screen_record"
                    color: collapsedLayout.startDisabled ? Qt.alpha(Colours.palette.m3onSurface, 0.38) : collapsedLayout.textColour
                    fill: 1
                }

                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Tr.tr("Record screen")
                    color: collapsedLayout.startDisabled ? Qt.alpha(Colours.palette.m3onSurface, 0.38) : collapsedLayout.textColour
                    font: Tokens.font.body.medium
                }
            }
        }

        StyledRect {
            id: expandChip

            radius: implicitHeight / 2 * Math.min(1, Tokens.rounding.scale)
            topLeftRadius: Tokens.rounding.medium / 2
            bottomLeftRadius: Tokens.rounding.medium / 2
            color: collapsedLayout.colour

            implicitWidth: implicitHeight
            implicitHeight: expandIcon.implicitHeight + collapsedLayout.verticalPadding * 2

            StateLayer {
                rect.topLeftRadius: parent.topLeftRadius
                rect.bottomLeftRadius: parent.bottomLeftRadius
                color: collapsedLayout.textColour
                onClicked: root.props.recordingCardExpanded = true
            }

            MaterialIcon {
                id: expandIcon

                anchors.centerIn: parent
                anchors.horizontalCenterOffset: -Math.floor(collapsedLayout.verticalPadding / 4)
                text: "expand_more"
                color: collapsedLayout.textColour
            }
        }
    }

    ColumnLayout {
        id: expandedLayout

        // Top/left/right only: keep natural height while the parent clips during collapse.
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Tokens.padding.large
        spacing: Tokens.spacing.medium
        // Stay in tree while parent height animates; opacity avoids hit-testing when collapsed.
        opacity: root.implicitHeight > 0.5 ? 1 : 0
        enabled: root.effectivelyExpanded

        RowLayout {
            spacing: Tokens.spacing.medium

            StyledRect {
                implicitWidth: implicitHeight
                implicitHeight: {
                    const h = icon.implicitHeight + Tokens.padding.small * 2;
                    return h - (h % 2);
                }

                radius: Tokens.rounding.full
                color: Recorder.running ? Colours.palette.m3secondary : Colours.palette.m3secondaryContainer

                MaterialIcon {
                    id: icon

                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: 1
                    text: "screen_record"
                    color: Recorder.running ? Colours.palette.m3onSecondary : Colours.palette.m3onSecondaryContainer
                    fontStyle: Tokens.font.icon.large
                }
            }

            Item {
                Layout.fillWidth: true
            }

            SplitButton {
                disabled: Recorder.running || Recorder.arming
                menuOnTop: true

                active: menuItems.find(m => root.props.recordingMode === m.icon + m.text) ?? menuItems[0]
                menu.onItemSelected: item => root.props.recordingMode = item.icon + item.text

                menuItems: [
                    MenuItem {
                        icon: "fullscreen"
                        text: Tr.tr("Record fullscreen")
                        activeText: Tr.trCtx("Fullscreen", "recording mode")
                        onClicked: Recorder.start()
                    },
                    MenuItem {
                        icon: "screenshot_region"
                        text: Tr.tr("Record region")
                        activeText: Tr.trCtx("Region", "recording mode")
                        onClicked: Recorder.start(["-r"])
                    },
                    MenuItem {
                        icon: "select_to_speak"
                        text: Tr.tr("Record fullscreen with sound")
                        activeText: Tr.trCtx("Fullscreen", "recording mode")
                        onClicked: Recorder.start(["-s"])
                    },
                    MenuItem {
                        icon: "volume_up"
                        text: Tr.tr("Record region with sound")
                        activeText: Tr.trCtx("Region", "recording mode")
                        onClicked: Recorder.start(["-sr"])
                    }
                ]
            }
        }

        Loader {
            id: listOrControls

            property bool running: Recorder.running

            asynchronous: true
            Layout.fillWidth: true
            Layout.preferredHeight: implicitHeight
            sourceComponent: running ? recordingControls : recordingList
            clip: Layout.preferredHeight < implicitHeight

            Behavior on Layout.preferredHeight {
                id: locHeightAnim

                enabled: false

                Anim {}
            }

            Behavior on running {
                SequentialAnimation {
                    Anim {
                        target: listOrControls
                        property: "opacity"
                        to: 0
                        type: Anim.DefaultEffects
                    }
                    PropertyAction {
                        target: locHeightAnim
                        property: "enabled"
                        value: true
                    }
                    PropertyAction {}
                    ParallelAnimation {
                        SequentialAnimation {
                            PauseAnimation {
                                duration: 100
                            }
                            PropertyAction {
                                target: locHeightAnim
                                property: "enabled"
                                value: false
                            }
                        }
                        Anim {
                            target: listOrControls
                            property: "opacity"
                            to: 1
                            type: Anim.SlowEffects
                        }
                    }
                }
            }
        }
    }

    Component {
        id: recordingList

        RecordingList {
            props: root.props
            screenState: root.screenState
        }
    }

    Component {
        id: recordingControls

        RowLayout {
            spacing: Tokens.spacing.medium

            StyledRect {
                radius: Tokens.rounding.full
                color: Recorder.paused ? Colours.palette.m3tertiary : Colours.palette.m3error

                implicitWidth: recText.implicitWidth + Tokens.padding.medium * 2
                implicitHeight: recText.implicitHeight + Tokens.padding.large

                StyledText {
                    id: recText

                    anchors.centerIn: parent
                    animate: true
                    text: Recorder.paused ? Tr.trCtx("PAUSED", "recording status") : Tr.trCtx("REC", "recording status")
                    color: Recorder.paused ? Colours.palette.m3onTertiary : Colours.palette.m3onError
                    font: Tokens.font.mono.small
                }

                Behavior on implicitWidth {
                    Anim {}
                }

                SequentialAnimation on opacity {
                    running: !Recorder.paused
                    alwaysRunToEnd: true
                    loops: Animation.Infinite

                    Anim {
                        from: 1
                        to: 0
                        duration: Tokens.anim.durations.large
                        easing: Tokens.anim.emphasizedAccel
                    }
                    Anim {
                        from: 0
                        to: 1
                        duration: Tokens.anim.durations.extraLarge
                        easing: Tokens.anim.emphasizedDecel
                    }
                }
            }

            StyledText {
                Layout.fillWidth: true
                text: {
                    const elapsed = Recorder.elapsed;

                    const hours = Math.floor(elapsed / 3600);
                    const mins = Math.floor((elapsed % 3600) / 60);
                    const secs = Math.floor(elapsed % 60).toString().padStart(2, "0");

                    let time;
                    if (hours > 0)
                        time = `${hours}:${mins.toString().padStart(2, "0")}:${secs}`;
                    else
                        time = `${mins}:${secs}`;

                    // TRANSLATORS: %1 = elapsed recording duration, e.g. 01:23
                    return Tr.tr("Recording for %1").arg(time);
                }
                font: Tokens.font.body.medium
                elide: Text.ElideMiddle
            }

            ButtonRow {
                spacing: Tokens.spacing.extraSmall

                IconButton {
                    shapeMorph: true
                    isRound: true
                    label.animate: true
                    icon: Recorder.paused ? "play_arrow" : "pause"
                    isToggle: true
                    checked: Recorder.paused
                    type: IconButton.Tonal
                    font: Tokens.font.icon.medium
                    onClicked: {
                        Recorder.togglePause();
                        internalChecked = Recorder.paused;
                    }

                    implicitWidth: {
                        const h = label.implicitHeight + Tokens.padding.large * 2;
                        if (h % 2 !== 0)
                            return h + 1;
                        return h;
                    }
                }

                IconButton {
                    shapeMorph: true
                    isRound: true
                    icon: "stop"
                    inactiveColour: Colours.palette.m3error
                    inactiveOnColour: Colours.palette.m3onError
                    font: Tokens.font.icon.medium
                    onClicked: Recorder.stop()

                    implicitWidth: {
                        const h = label.implicitHeight + Tokens.padding.large * 2;
                        if (h % 2 !== 0)
                            return h + 1;
                        return h;
                    }
                }
            }
        }
    }
}
