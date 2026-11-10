pragma Singleton

import QtQuick
import Quickshell
import Sylphrena.Config
import Sylphrena.I18n
import qs.services

// Registry of the widgets that can live in the dashboard carousel (centre of the Dashboard tab).
//
// To add a widget: add an entry to `all`, make `isEnabled()` say when it shows, add a case in
// modules/dashboard/dash/WidgetCarousel.qml and (if it has options) a card in the Nexus
// Dashboard page. The order lives in config (`dashboard.widgetOrder`); unknown ids are ignored and
// missing ones are appended, so old configs keep working when widgets are added.
Singleton {
    id: root

    readonly property var all: [
        {
            id: "calendar",
            title: Tr.tr("Calendar"),
            subtext: Tr.tr("Month view of the dashboard"),
            icon: "calendar_month",
            always: true
        },
        {
            id: "hydration",
            title: Tr.tr("Hydration"),
            subtext: Tr.tr("Water intake tracker with reminders"),
            icon: "water_drop",
            always: false
        }
    ]

    // All widgets in the user's order (enabled or not)
    readonly property var order: {
        const saved = Array.from(GlobalConfig.dashboard.widgetOrder ?? []);
        const out = [];
        for (const id of saved) {
            const w = all.find(x => x.id === id);
            if (w && !out.includes(w))
                out.push(w);
        }
        for (const w of all)
            if (!out.includes(w))
                out.push(w);
        return out;
    }

    // Widgets actually shown in the carousel, in order
    readonly property var active: order.filter(w => isEnabled(w.id))

    function isEnabled(id: string): bool {
        if (id === "hydration")
            return Hydration.enabled;
        return true;
    }

    // Move a widget one place up (-1) or down (+1) in the order
    function move(id: string, delta: int): void {
        const ids = order.map(w => w.id);
        const i = ids.indexOf(id);
        const j = i + delta;
        if (i < 0 || j < 0 || j >= ids.length)
            return;
        [ids[i], ids[j]] = [ids[j], ids[i]];
        GlobalConfig.dashboard.widgetOrder = ids;
    }
}
