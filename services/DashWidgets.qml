pragma Singleton

import QtQuick
import Quickshell
import Sylphrena.Config
import Sylphrena.I18n
import qs.services

// Registry of the widgets that can live in the dashboard carousel (centre of the Dashboard tab).
//
// Two sources, one list:
//   - `builtin`: widgets the shell ships itself (only the calendar);
//   - widgets declared by extensions (services/Extensions.qml), found through their manifests.
//     Extensions are never named here: adding one needs no change to this file.
// The order lives in config (`dashboard.widgetOrder`); unknown ids are ignored and missing ones are
// appended, so configs keep working when widgets come and go.
Singleton {
    id: root

    readonly property var builtin: [
        {
            id: "calendar",
            title: Tr.tr("Calendar"),
            subtext: Tr.tr("Month view of the dashboard"),
            icon: "calendar_month"
        }
    ]

    // Every widget that exists, enabled or not. Extension strings are looked up in the shell's
    // translations (Tr.tr works with any key present in es.po).
    readonly property var all: builtin.concat(Extensions.widgetDecls.map(w => ({
                id: w.id,
                ext: w.extId,
                title: Tr.tr(w.title),
                subtext: w.subtext ? Tr.tr(w.subtext) : "",
                offNote: w.offNote ? Tr.tr(w.offNote) : "",
                hasSettings: w.hasSettings,
                icon: w.icon
            })))

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

    // Widgets actually shown in the carousel, in order. An extension widget carries its `entry`
    // ({ id, ext, component }); one whose extension failed to load is left out.
    readonly property var active: {
        const out = [];
        for (const w of order) {
            if (!isEnabled(w.id))
                continue;
            if (w.ext) {
                const entry = Extensions.widgets.find(x => x.id === w.id);
                if (entry)
                    out.push(Object.assign({}, w, { entry }));
            } else {
                out.push(w);
            }
        }
        return out;
    }

    function isEnabled(id: string): bool {
        const w = all.find(x => x.id === id);
        if (w?.ext)
            return Extensions.isEnabled(w.ext);
        if (id === "calendar")
            return GlobalConfig.dashboard.calendarEnabled;
        return false;
    }

    function setEnabled(id: string, on: bool): void {
        const w = all.find(x => x.id === id);
        if (w?.ext)
            Extensions.setEnabled(w.ext, on);
        else if (id === "calendar")
            GlobalConfig.dashboard.calendarEnabled = on;
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
