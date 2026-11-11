pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Sylphrena.Config
import Sylphrena.I18n
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus
import qs.modules.nexus.common

// The welcome assistant window (see services/Welcome.qml): what Sylphrena is, what it offers, and
// the apps of its family that are worth installing. Five steps; skipping or finishing both count as seen.
FloatingWindow {
    id: win

    readonly property int stepCount: 5
    property int step: 0

    property bool done: false

    // The orb is one item of the window that flies to the slot each step reserves for it: big and
    // centred in the first one, small beside the title in the rest. Position = centre of the orb.
    property Item slot: null
    property real slotOrb: 150
    property real orbCx: 0
    property real orbCy: 0
    property real orbPx: 150
    // False until the first placement: the orb must not fly in from a corner when the window opens
    property bool placed: false

    function registerSlot(item: Item, orbSize: real): void {
        win.slot = item;
        win.slotOrb = orbSize;
        settle.restart();
    }

    function syncOrb(): void {
        if (!win.slot)
            return;
        const p = win.slot.mapToItem(win.contentItem, win.slot.width / 2, win.slot.height / 2);
        win.orbCx = p.x;
        win.orbCy = p.y;
        win.orbPx = win.slotOrb;
        if (!win.placed)
            Qt.callLater(() => win.placed = true);
    }

    signal finished

    // Close the window (finishing, skipping or closing it by hand all end up here)
    function dismiss(): void {
        if (win.done)
            return;
        win.done = true;
        win.finished();
        win.destroy();
    }

    title: Tr.tr("Welcome to Sylphrena")
    color: Colours.tPalette.m3surface
    surfaceFormat.opaque: false
    // A small window of fixed size: Hyprland floats those (and centres them) instead of tiling them
    readonly property int windowWidth: 960
    readonly property int windowHeight: 720
    implicitWidth: windowWidth
    implicitHeight: windowHeight
    minimumSize.width: windowWidth
    minimumSize.height: windowHeight
    maximumSize.width: windowWidth
    maximumSize.height: windowHeight

    contentItem.Config.screen: screen.name
    contentItem.Tokens.screen: screen.name

    onVisibleChanged: {
        if (!visible)
            win.dismiss();
    }

    // Layout settles a moment after a page loads or the window is resized: place the orb then
    onWidthChanged: settle.restart()
    onHeightChanged: settle.restart()

    Timer {
        id: settle

        interval: 60
        onTriggered: win.syncOrb()
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Tokens.padding.extraLarge
        spacing: Tokens.spacing.large

        // ---- Pages ----------------------------------------------------------------------
        Loader {
            id: pages

            Layout.fillWidth: true
            Layout.fillHeight: true
            sourceComponent: [welcomePage, offerPage, companionsPage, shortcutsPage, donePage][win.step]

            onLoaded: fade.restart()

            NumberAnimation {
                id: fade

                target: pages.item
                property: "opacity"
                from: 0
                to: 1
                duration: Tokens.anim.durations.normal
            }
        }

        // ---- Footer ---------------------------------------------------------------------
        Item {
            Layout.fillWidth: true
            implicitHeight: buttons.implicitHeight

            // Step dots, centred whatever the buttons on the sides are
            Row {
                anchors.centerIn: parent
                spacing: Tokens.spacing.small

                Repeater {
                    model: win.stepCount

                    Rectangle {
                        required property int index

                        anchors.verticalCenter: parent.verticalCenter
                        width: index === win.step ? Tokens.padding.large : Tokens.padding.small
                        height: Tokens.padding.small
                        radius: height / 2
                        color: index === win.step ? Colours.palette.m3primary : Colours.palette.m3outlineVariant

                        Behavior on width {
                            Anim {}
                        }
                    }
                }
            }

            RowLayout {
                id: buttons

                anchors.left: parent.left
                anchors.right: parent.right
                spacing: Tokens.spacing.medium

                TextButton {
                    visible: win.step < win.stepCount - 1
                    text: Tr.tr("Skip")
                    type: TextButton.Text
                    isRound: true
                    horizontalPadding: Tokens.padding.large
                    verticalPadding: Tokens.padding.small
                    onClicked: win.dismiss()
                }

                Item {
                    Layout.fillWidth: true
                }

                TextButton {
                    visible: win.step > 0
                    text: Tr.tr("Back")
                    type: TextButton.Tonal
                    isRound: true
                    horizontalPadding: Tokens.padding.extraLarge
                    verticalPadding: Tokens.padding.medium
                    onClicked: win.step--
                }

                TextButton {
                    text: win.step < win.stepCount - 1 ? Tr.tr("Next") : Tr.tr("Finish")
                    isRound: true
                    horizontalPadding: Tokens.padding.extraLarge
                    verticalPadding: Tokens.padding.medium
                    onClicked: win.step < win.stepCount - 1 ? win.step++ : win.dismiss()
                }
            }
        }
    }

    // The orb (above the pages)
    SylphOrb {
        id: orb

        x: win.orbCx - width / 2
        y: win.orbCy - height / 2
        orbSize: Math.round(win.orbPx)

        Behavior on x {
            enabled: win.placed

            Anim {
                type: Anim.DefaultSpatial
            }
        }

        Behavior on y {
            enabled: win.placed

            Anim {
                type: Anim.DefaultSpatial
            }
        }

        Behavior on orbSize {
            enabled: win.placed

            Anim {
                type: Anim.DefaultSpatial
            }
        }
    }

    // Header of the steps after the first: a slot for the small orb, then title and subtitle
    component PageHeader: RowLayout {
        id: header

        property string title
        property string subtitle

        signal slotReady(Item slot, real orbSize)

        Layout.fillWidth: true
        spacing: Tokens.spacing.medium

        Item {
            id: headerSlot

            Layout.alignment: Qt.AlignVCenter
            implicitWidth: 56
            implicitHeight: 56

            Component.onCompleted: header.slotReady(headerSlot, 36)
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.extraSmall / 2

            StyledText {
                text: header.title
                font: Tokens.font.headline.medium
            }

            StyledText {
                Layout.fillWidth: true
                text: header.subtitle
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.body.medium
                wrapMode: Text.WordWrap
            }
        }
    }

    // ── 1 · Who Sylphrena is ──────────────────────────────────────────────────────────────
    Component {
        id: welcomePage

        ColumnLayout {
            spacing: Tokens.spacing.large

            Item {
                Layout.fillHeight: true
            }

            // Where the orb sits in this step (it is the window's orb, see above)
            Item {
                id: heroSlot

                Layout.alignment: Qt.AlignHCenter
                implicitWidth: 150 * 1.55
                implicitHeight: 150 * 1.55

                Component.onCompleted: win.registerSlot(heroSlot, 150)
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: "Sylphrena"
                font: Tokens.font.headline.medium
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                Layout.maximumWidth: 560
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                text: Tr.tr("A Material You desktop shell for Hyprland, made to be yours: every look, shortcut and widget can be changed, and what you do not need can be left out.")
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.body.large
            }

            // Who makes it
            ColumnLayout {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: Tokens.spacing.medium
                spacing: Tokens.spacing.extraSmall

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    // TRANSLATORS: %1 = the author's name on GitHub
                    text: Tr.tr("Made by %1").arg("iMacnucintosh")
                    font: Tokens.font.title.small
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    // TRANSLATORS: %1 = the name of the original project, %2 = its author
                    text: Tr.tr("A fork of %1 by %2").arg("caelestia-shell").arg("soramane")
                    color: Colours.palette.m3outline
                    font: Tokens.font.label.medium
                }
            }

            IconTextButton {
                Layout.alignment: Qt.AlignHCenter
                isRound: true
                type: IconTextButton.Tonal
                horizontalPadding: Tokens.padding.large
                verticalPadding: Tokens.padding.small
                icon: "open_in_new"
                text: "GitHub"
                onClicked: Quickshell.execDetached(["xdg-open", "https://github.com/iMacnucintosh/sylphrena-shell"])
            }

            Item {
                Layout.fillHeight: true
            }
        }
    }

    // ── 2 · What it offers ────────────────────────────────────────────────────────────────
    Component {
        id: offerPage

        ColumnLayout {
            spacing: Tokens.spacing.large

            PageHeader {
                title: Tr.tr("What Sylphrena gives you")
                subtitle: Tr.tr("A quick look. Everything is in Nexus, the settings window.")
                onSlotReady: (slot, size) => win.registerSlot(slot, size)
            }

            GridLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                columns: 2
                rowSpacing: Tokens.spacing.medium
                columnSpacing: Tokens.spacing.medium

                Repeater {
                    model: [
                        {
                            icon: "grid_view",
                            title: Tr.tr("Activities"),
                            text: Tr.tr("A look for each part of your day: wallpaper, colours and the apps pinned to its desktops.")
                        },
                        {
                            icon: "tune",
                            title: "Nexus",
                            text: Tr.tr("Every setting in one window, with search.")
                        },
                        {
                            icon: "space_dashboard",
                            title: Tr.tr("Dashboard"),
                            text: Tr.tr("Weather, music, performance and your widgets at a glance.")
                        },
                        {
                            icon: "palette",
                            title: "Material You",
                            text: Tr.tr("Colours that follow your wallpaper, in the shell and in your apps.")
                        },
                        {
                            icon: "extension",
                            title: Tr.tr("Extensions"),
                            text: Tr.tr("Add only what you need: widgets, VPN, games and more. Or build your own.")
                        },
                        {
                            icon: "lock",
                            title: Tr.tr("Lock and login"),
                            text: Tr.tr("A lock screen and a login screen that match the shell.")
                        }
                    ]

                    ConnectedRect {
                        id: card

                        required property var modelData

                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.preferredWidth: 1
                        implicitHeight: cardCol.implicitHeight + Tokens.padding.large * 2
                        first: true
                        last: true

                        ColumnLayout {
                            id: cardCol

                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: Tokens.padding.large
                            spacing: Tokens.spacing.small

                            MaterialIcon {
                                text: card.modelData.icon
                                color: Colours.palette.m3primary
                                fontStyle: Tokens.font.icon.large
                                fill: 1
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: card.modelData.title
                                font: Tokens.font.title.small
                                elide: Text.ElideRight
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: card.modelData.text
                                color: Colours.palette.m3onSurfaceVariant
                                font: Tokens.font.body.small
                                wrapMode: Text.WordWrap
                            }
                        }
                    }
                }
            }
        }
    }

    // ── 3 · Apps that come with Sylphrena (informative: the base package installs them) ────
    Component {
        id: companionsPage

        ColumnLayout {
            spacing: Tokens.spacing.large

            Component.onCompleted: Companions.check()

            PageHeader {
                title: Tr.tr("Apps made for Sylphrena")
                subtitle: Tr.tr("They come with Sylphrena and follow its theme.")
                onSlotReady: (slot, size) => win.registerSlot(slot, size)
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.extraSmall / 2

                Repeater {
                    model: ["seeker", "things", "kitty"]

                    ConnectedRect {
                        id: appCard

                        required property string modelData
                        required property int index
                        readonly property var app: Companions.find(modelData)
                        readonly property bool installed: Companions.isInstalled(modelData)

                        Layout.fillWidth: true
                        first: index === 0
                        last: index === 2
                        implicitHeight: appRow.implicitHeight + Tokens.padding.large * 2

                        RowLayout {
                            id: appRow

                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.margins: Tokens.padding.large
                            spacing: Tokens.spacing.medium

                            MaterialIcon {
                                Layout.alignment: Qt.AlignVCenter
                                text: appCard.app.icon
                                color: Colours.palette.m3primary
                                fontStyle: Tokens.font.icon.extraLarge
                                fill: 1
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0

                                StyledText {
                                    Layout.fillWidth: true
                                    text: appCard.app.name
                                    font: Tokens.font.title.medium
                                }

                                StyledText {
                                    Layout.fillWidth: true
                                    text: appCard.app.description
                                    color: Colours.palette.m3onSurfaceVariant
                                    font: Tokens.font.body.small
                                    wrapMode: Text.WordWrap
                                }
                            }

                            TextButton {
                                visible: appCard.installed
                                Layout.alignment: Qt.AlignVCenter
                                type: TextButton.Tonal
                                isRound: true
                                horizontalPadding: Tokens.padding.large
                                verticalPadding: Tokens.padding.small
                                text: Tr.tr("Open")
                                onClicked: Companions.launch(appCard.modelData)
                            }

                            StyledText {
                                visible: Companions.checked && !appCard.installed
                                Layout.alignment: Qt.AlignVCenter
                                text: Tr.tr("Not installed")
                                color: Colours.palette.m3outline
                                font: Tokens.font.label.medium
                            }
                        }
                    }
                }
            }

            // kitty comes with Sylphrena, but nobody is tied to it
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: Tokens.spacing.small
                spacing: Tokens.spacing.medium

                MaterialIcon {
                    Layout.alignment: Qt.AlignVCenter
                    text: "swap_horiz"
                    color: Colours.palette.m3onSurfaceVariant
                    fontStyle: Tokens.font.icon.large
                }

                StyledText {
                    Layout.fillWidth: true
                    text: Tr.tr("kitty comes preinstalled, but you can use any terminal you like.")
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.body.medium
                    wrapMode: Text.WordWrap
                }

                TextButton {
                    Layout.alignment: Qt.AlignVCenter
                    type: TextButton.Tonal
                    isRound: true
                    horizontalPadding: Tokens.padding.large
                    verticalPadding: Tokens.padding.small
                    text: Tr.tr("Choose terminal")
                    onClicked: WindowFactory.openPage("apps")
                }
            }

            Item {
                Layout.fillHeight: true
            }
        }
    }

    // ── 4 · The shortcuts ───────────────────────────────────────────────────────────────────
    // What is bound right now (it follows Nexus: edit a shortcut there and it changes here)
    Component {
        id: shortcutsPage

        ColumnLayout {
            id: sc

            spacing: Tokens.spacing.large

            // Keycap names for what Hyprland calls the keys
            readonly property var keyNames: ({
                    super: "Super",
                    ctrl: "Ctrl",
                    alt: "Alt",
                    shift: "Shift",
                    left: "←",
                    right: "→",
                    up: "↑",
                    down: "↓",
                    grave: "`",
                    comma: ",",
                    space: Tr.tr("Space"),
                    equal: "=",
                    minus: "−",
                    backspace: "⌫",
                    delete: "Del",
                    print: Tr.tr("PrtSc"),
                    tab: "Tab",
                    "mouse:272": Tr.tr("Left click"),
                    "mouse:273": Tr.tr("Right click"),
                    mouse_down: Tr.tr("Wheel ↓"),
                    mouse_up: Tr.tr("Wheel ↑")
                })

            function keys(bind: string): var {
                if (!bind)
                    return [];
                return bind.split("+").map(k => k.trim()).filter(k => k).map(k => sc.keyNames[k.toLowerCase()] ?? k);
            }

            // Numbered families collapse into one row ("Super + 1…0")
            readonly property var rows: {
                Keybinds.overrides; // follow the edits
                const out = [];
                const families = [
                    {
                        prefix: "workspace",
                        label: Tr.tr("Go to workspace 1–10")
                    },
                    {
                        prefix: "moveToWorkspace",
                        label: Tr.tr("Move window to workspace 1–10")
                    },
                    {
                        prefix: "activityGo",
                        label: Tr.tr("Go to activity 1–4")
                    }
                ];
                const isNumbered = id => families.some(f => id.startsWith(f.prefix) && /^\d+$/.test(id.slice(f.prefix.length)));
                for (const cat of ["windows", "workspaces", "activities", "apps", "shell", "notifications", "media", "system", "capture"]) {
                    const acts = Keybinds.catalog.filter(a => a.category === cat);
                    if (!acts.length)
                        continue;
                    out.push({
                        header: Keybinds.categoryLabels[cat]()
                    });
                    for (const f of families) {
                        const first = acts.find(a => a.id === f.prefix + "1");
                        if (first)
                            out.push({
                                label: f.label,
                                keys: sc.keys(Keybinds.bindFor(first.id)).map((k, i, a) => i === a.length - 1 ? k + "…" : k)
                            });
                    }
                    for (const a of acts) {
                        if (isNumbered(a.id))
                            continue;
                        out.push({
                            label: a.label(),
                            keys: sc.keys(Keybinds.bindFor(a.id))
                        });
                    }
                }
                return out;
            }

            PageHeader {
                title: Tr.tr("Your shortcuts")
                subtitle: Tr.tr("These are the ones in use now. Change any of them in Nexus and they update here.")
                onSlotReady: (slot, size) => win.registerSlot(slot, size)
            }

            StyledRect {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: Tokens.rounding.large
                color: Colours.tPalette.m3surfaceContainer
                clip: true

                ListView {
                    anchors.fill: parent
                    anchors.margins: Tokens.padding.medium
                    clip: true
                    spacing: 2
                    model: sc.rows
                    boundsBehavior: Flickable.StopAtBounds

                    delegate: Item {
                        id: row

                        required property var modelData

                        width: ListView.view.width
                        implicitHeight: row.modelData.header ? 34 : 30

                        StyledText {
                            visible: !!row.modelData.header
                            anchors.left: parent.left
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 4
                            text: row.modelData.header ?? ""
                            color: Colours.palette.m3primary
                            font: Tokens.font.label.large
                        }

                        StyledText {
                            visible: !row.modelData.header
                            anchors.left: parent.left
                            anchors.leftMargin: Tokens.padding.small
                            anchors.right: caps.left
                            anchors.verticalCenter: parent.verticalCenter
                            text: row.modelData.label ?? ""
                            elide: Text.ElideRight
                            font: Tokens.font.body.medium
                        }

                        Row {
                            id: caps

                            visible: !row.modelData.header
                            anchors.right: parent.right
                            anchors.rightMargin: Tokens.padding.small
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 4

                            StyledText {
                                visible: (row.modelData.keys ?? []).length === 0
                                text: Tr.tr("None")
                                color: Colours.palette.m3outline
                                font: Tokens.font.label.medium
                            }

                            Repeater {
                                model: row.modelData.keys ?? []

                                StyledRect {
                                    id: cap

                                    required property string modelData

                                    implicitWidth: Math.max(capLabel.implicitWidth + Tokens.padding.medium * 2, 26)
                                    implicitHeight: capLabel.implicitHeight + Tokens.padding.small
                                    radius: Tokens.rounding.small
                                    color: Colours.tPalette.m3surfaceContainerHighest

                                    StyledText {
                                        id: capLabel

                                        anchors.centerIn: parent
                                        text: cap.modelData
                                        font: Tokens.font.label.medium
                                    }
                                }
                            }
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.medium

                StyledText {
                    Layout.fillWidth: true
                    text: Tr.tr("In Nexus you can also export and import them.")
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.body.small
                    wrapMode: Text.WordWrap
                }

                TextButton {
                    type: TextButton.Tonal
                    isRound: true
                    horizontalPadding: Tokens.padding.large
                    verticalPadding: Tokens.padding.small
                    text: Tr.tr("Edit in Nexus")
                    onClicked: WindowFactory.openPage("keybinds")
                }
            }
        }
    }

    // ── 5 · Ready ─────────────────────────────────────────────────────────────────────────
    Component {
        id: donePage

        ColumnLayout {
            spacing: Tokens.spacing.large

            PageHeader {
                title: Tr.tr("You are all set")
                subtitle: Tr.tr("Open Nexus whenever you want to change something. This guide is in Nexus → About.")
                onSlotReady: (slot, size) => win.registerSlot(slot, size)
            }

            // Invitation to build extensions
            ConnectedRect {
                Layout.fillWidth: true
                Layout.topMargin: Tokens.spacing.large
                first: true
                last: true
                implicitHeight: makeCol.implicitHeight + Tokens.padding.large * 2

                ColumnLayout {
                    id: makeCol

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: Tokens.padding.large
                    spacing: Tokens.spacing.medium

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Tokens.spacing.medium

                        MaterialIcon {
                            Layout.alignment: Qt.AlignTop
                            text: "code"
                            color: Colours.palette.m3primary
                            fontStyle: Tokens.font.icon.extraLarge
                            fill: 1
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Tokens.spacing.extraSmall

                            StyledText {
                                Layout.fillWidth: true
                                text: Tr.tr("Make it yours: create your own extensions")
                                font: Tokens.font.title.medium
                                wrapMode: Text.WordWrap
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: Tr.tr("An extension is a folder with a manifest and a few QML files. Build one for yourself, and share it in the Sylphrena Hub for others to install.")
                                color: Colours.palette.m3onSurfaceVariant
                                font: Tokens.font.body.medium
                                wrapMode: Text.WordWrap
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Tokens.spacing.small

                        Item {
                            Layout.fillWidth: true
                        }

                        IconTextButton {
                            isRound: true
                            horizontalPadding: Tokens.padding.large
                            verticalPadding: Tokens.padding.small
                            icon: "open_in_new"
                            text: Tr.tr("Sylphrena Hub")
                            onClicked: Quickshell.execDetached(["xdg-open", "https://github.com/iMacnucintosh/sylphrena-hub"])
                        }
                    }
                }
            }

            Item {
                Layout.fillHeight: true
            }

            IconTextButton {
                Layout.alignment: Qt.AlignHCenter
                isRound: true
                type: IconTextButton.Tonal
                horizontalPadding: Tokens.padding.large
                verticalPadding: Tokens.padding.medium
                icon: "tune"
                text: Tr.tr("Open Nexus")
                onClicked: WindowFactory.openPage("activities")
            }

            Item {
                Layout.fillHeight: true
            }
        }
    }
}
