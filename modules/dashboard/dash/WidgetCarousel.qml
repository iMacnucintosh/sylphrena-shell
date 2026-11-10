pragma ComponentBehavior: Bound

import QtQuick
import Sylphrena.Config
import Sylphrena.I18n
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus

// Centre of the dashboard: one widget at a time (calendar, hydration, …), switched by hand with
// the dots, the wheel or a horizontal drag. Which widgets exist and their order come from
// services/DashWidgets.qml. With a single widget there are no controls and it looks fixed.
Item {
    id: root

    required property ScreenState screenState

    readonly property var widgets: DashWidgets.active
    readonly property int count: widgets.length
    readonly property bool multi: count > 1
    // Remembered by widget id in the screen state: reopening the panel shows the same page, and it
    // survives widgets being reordered or switched off (falls back to the first one)
    readonly property int current: {
        const i = widgets.findIndex(w => w.id === screenState.dashboardWidget);
        return i >= 0 ? i : 0;
    }
    // Live horizontal drag offset in px (0 when idle)
    property real dragOffset: 0
    property real wheelAcc: 0

    implicitHeight: pages.maxHeight

    // Slide only when the user switches page; opening the panel / reordering must not animate
    property bool userSwitch: false

    Timer {
        id: switchTimer

        interval: 800
        onTriggered: root.userSwitch = false
    }

    function go(i: int): void {
        userSwitch = true;
        switchTimer.restart();
        const w = widgets[Math.max(0, Math.min(count - 1, i))];
        if (w)
            screenState.dashboardWidget = w.id;
    }

    Item {
        id: pages

        // Tallest widget, so the dashboard does not jump when switching pages
        property real maxHeight: 0

        function recalc(): void {
            let h = 0;
            for (let i = 0; i < repeater.count; ++i) {
                const it = repeater.itemAt(i);
                if (it)
                    h = Math.max(h, it.contentHeight);
            }
            maxHeight = h;
        }

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        clip: true

        Repeater {
            id: repeater

            model: root.widgets

            onItemAdded: pages.recalc()
            onItemRemoved: pages.recalc()

            delegate: Item {
                id: page

                required property var modelData
                required property int index

                readonly property real contentHeight: loader.item ? loader.item.implicitHeight : 0
                readonly property Item loaderItem: loader.item

                onContentHeightChanged: pages.recalc()

                x: (index - root.current) * width + root.dragOffset
                width: pages.width
                height: pages.height
                // Only what is on screen (or sliding in) is alive: hydration animates at ~60 fps
                visible: Math.abs(x) < width

                Behavior on x {
                    enabled: root.dragOffset === 0 && root.userSwitch

                    Anim {
                        type: Anim.DefaultSpatial
                    }
                }

                Loader {
                    id: loader

                    anchors.fill: parent
                    sourceComponent: page.modelData.id === "hydration" ? hydrationComp : page.modelData.id === "tasks" ? tasksComp : calendarComp
                }
            }
        }

        DragHandler {
            id: drag

            enabled: root.multi
            target: null
            xAxis.enabled: true
            yAxis.enabled: false
            onTranslationChanged: root.dragOffset = translation.x
            onActiveChanged: {
                if (active)
                    return;
                const t = pages.width / 5;
                if (root.dragOffset < -t)
                    root.go(root.current + 1);
                else if (root.dragOffset > t)
                    root.go(root.current - 1);
                root.dragOffset = 0;
            }
        }

        // Wheel switches page (the calendar does not consume it here); one notch per step
        WheelHandler {
            enabled: root.multi
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            onWheel: event => {
                // A page can say where the wheel must NOT switch widget (e.g. over a scrolling list)
                const page = repeater.itemAt(root.current);
                const w = page?.loaderItem;
                if (w && w.wheelSwitchAllowed && !w.wheelSwitchAllowed(event.point.position.y))
                    return;
                const d = Math.abs(event.angleDelta.y) >= Math.abs(event.angleDelta.x) ? event.angleDelta.y : event.angleDelta.x;
                if (Math.sign(d) !== Math.sign(root.wheelAcc))
                    root.wheelAcc = 0;
                root.wheelAcc += d;
                if (Math.abs(root.wheelAcc) >= 120) {
                    root.go(root.current + (root.wheelAcc < 0 ? 1 : -1));
                    root.wheelAcc = 0;
                }
            }
        }

    }

    // Dots: overlaid on the widget, bottom centre, on a small translucent pill so they read on any page
    StyledRect {
        visible: root.multi
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Tokens.padding.small
        implicitWidth: dots.implicitWidth + Tokens.padding.medium * 2
        implicitHeight: dots.implicitHeight + Tokens.padding.small * 2
        radius: Tokens.rounding.full
        color: Qt.alpha(Colours.palette.m3surfaceContainerHighest, 0.75)

        Row {
            id: dots

            anchors.centerIn: parent
            spacing: 6

            Repeater {
                model: root.count

                delegate: Item {
                    id: dot

                    required property int index
                    readonly property bool on: index === root.current

                    width: on ? 18 : 8
                    height: 8

                    Behavior on width {
                        Anim {
                            type: Anim.FastSpatial
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: height / 2
                        color: dot.on ? Colours.palette.m3primary : Colours.palette.m3outline
                    }

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -4
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.go(dot.index)
                    }
                }
            }
        }
    }

    // Nothing enabled: a short prompt that jumps to the carousel settings
    Item {
        id: empty

        visible: root.count === 0
        anchors.fill: parent

        StyledRect {
            id: emptyBtn

            anchors.centerIn: parent
            implicitWidth: emptyRow.implicitWidth + Tokens.padding.large * 2
            implicitHeight: emptyRow.implicitHeight + Tokens.padding.medium * 2
            radius: Tokens.rounding.full
            color: Colours.palette.m3secondaryContainer

            StateLayer {
                radius: Tokens.rounding.full
                color: Colours.palette.m3onSecondaryContainer
                onClicked: WindowFactory.openSubPage("panels", 1)
            }

            Row {
                id: emptyRow

                anchors.centerIn: parent
                spacing: Tokens.spacing.small

                MaterialIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "widgets"
                    color: Colours.palette.m3onSecondaryContainer
                }

                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Tr.tr("Enable widgets")
                    color: Colours.palette.m3onSecondaryContainer
                    font: Tokens.font.label.large
                }
            }
        }
    }

    Component {
        id: calendarComp

        Calendar {
            screenState: root.screenState
            // The wheel switches carousel pages here, not months
            scrollable: false
        }
    }

    Component {
        id: tasksComp

        TasksWidget {
            screenState: root.screenState
        }
    }

    Component {
        id: hydrationComp

        HydrationWidget {}
    }
}
