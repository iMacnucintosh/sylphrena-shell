pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import Sylphrena
import Sylphrena.Config
import Sylphrena.I18n
import qs.services
import qs.utils

QtObject {
    id: notif

    property bool popup
    property bool closed
    property var locks: new Set()

    property date time: new Date()
    property int ageMins: 0
    readonly property string timeStr: {
        if (ageMins < 1)
            return Tr.tr("now");

        const h = Math.floor(ageMins / 60);
        const d = Math.floor(h / 24);

        if (d > 0)
            return Tr.trCtx("%1d", "abbreviated notification age, days").arg(d);
        if (h > 0)
            return Tr.trCtx("%1h", "abbreviated notification age, hours").arg(h);
        return Tr.trCtx("%1m", "abbreviated notification age, minutes").arg(ageMins);
    }

    readonly property Timer timeStrTimer: Timer {
        running: !notif.closed
        repeat: true
        interval: 5000
        onTriggered: notif.updateTimeStr()
    }

    property Notification notification
    property string notificationId
    property string summary
    property string body
    property string appIcon
    property string appName
    property string desktopEntry
    property string image
    // True when the sender was notify-send/libnotify: UI falls back to Material
    // "notifications" only if there is no real app icon.
    property bool useMaterialNotifIcon: false
    property var hints // Hints are not persisted across restarts
    // A progress bar under the body, 0..1 (-1: none): the standard "value" hint (0-100) of an app's notification,
    // or set directly by a notification of the shell (pushLocal({ localProgress: 0.5 }))
    property real localProgress: -1
    readonly property real progress: {
        const v = hints?.value;
        if (typeof v === "number" && v >= 0)
            return Math.min(1, v / 100);
        return localProgress;
    }
    property real expireTimeout: GlobalConfig.notifs.defaultExpireTimeout
    property int urgency: NotificationUrgency.Normal
    property bool resident
    property bool hasActionIcons
    property list<var> actions

    readonly property bool hasFullscreen: {
        const monitor = Hypr.focusedMonitor;
        const specialName = monitor?.lastIpcObject.specialWorkspace?.name;
        if (specialName) {
            const specialWs = Hypr.workspaces.values.find(ws => ws.name === specialName);
            return specialWs?.toplevels.values.some(t => t.lastIpcObject.fullscreen > 1) ?? false;
        }
        return monitor?.activeWorkspace?.toplevels.values.some(t => t.lastIpcObject.fullscreen > 1) ?? false;
    }

    readonly property Timer timer: Timer {
        // Only while the toast is showing — restored history entries must not
        // arm a one-shot, and re-showing a popup must re-arm expiry.
        running: notif.popup
        interval: notif.expireTimeout > 0 ? notif.expireTimeout : notif.hasFullscreen ? GlobalConfig.notifs.fullscreenExpireTimeout : GlobalConfig.notifs.defaultExpireTimeout
        onTriggered: {
            // Always expire if the active workspace has a fullscreen window
            if (GlobalConfig.notifs.expire || notif.hasFullscreen)
                notif.popup = false;
        }
    }

    readonly property LazyLoader dummyImageLoader: LazyLoader {
        active: false

        // qmllint disable uncreatable-type
        PanelWindow {
            // qmllint enable uncreatable-type
            implicitWidth: TokenConfig.sizes.notifs.image
            implicitHeight: TokenConfig.sizes.notifs.image
            color: "transparent"
            mask: Region {}

            Image {
                function tryCache(): void {
                    if (status !== Image.Ready || width != TokenConfig.sizes.notifs.image || height != TokenConfig.sizes.notifs.image)
                        return;

                    const cacheKey = notif.appName + notif.summary + notif.notificationId + notif.image;
                    let h1 = 0xdeadbeef, h2 = 0x41c6ce57, ch;
                    for (let i = 0; i < cacheKey.length; i++) {
                        ch = cacheKey.charCodeAt(i);
                        h1 = Math.imul(h1 ^ ch, 2654435761);
                        h2 = Math.imul(h2 ^ ch, 1597334677);
                    }
                    h1 = Math.imul(h1 ^ (h1 >>> 16), 2246822507);
                    h1 ^= Math.imul(h2 ^ (h2 >>> 13), 3266489909);
                    h2 = Math.imul(h2 ^ (h2 >>> 16), 2246822507);
                    h2 ^= Math.imul(h1 ^ (h1 >>> 13), 3266489909);
                    const hash = (h2 >>> 0).toString(16).padStart(8, 0) + (h1 >>> 0).toString(16).padStart(8, 0);

                    const cache = `${Paths.notifimagecache}/${hash}.png`;
                    CUtils.saveItem(this, Qt.resolvedUrl(cache), () => {
                        notif.image = cache;
                        notif.dummyImageLoader.active = false;
                    });
                }

                anchors.fill: parent
                source: Qt.resolvedUrl(notif.image)
                fillMode: Image.PreserveAspectCrop
                cache: false
                asynchronous: true
                opacity: 0

                onStatusChanged: tryCache()
                onWidthChanged: tryCache()
                onHeightChanged: tryCache()
            }
        }
    }

    readonly property Connections conn: Connections {
        function onClosed(): void {
            notif.close();
        }

        function onSummaryChanged(): void {
            notif.summary = notif.notification.summary;
        }

        function onBodyChanged(): void {
            notif.body = notif.notification.body;
        }

        function onAppIconChanged(): void {
            notif.appIcon = notif.notification.appIcon;
            notif.normalizeIdentity();
        }

        function onAppNameChanged(): void {
            notif.appName = notif.notification.appName;
            notif.normalizeIdentity();
        }

        function onDesktopEntryChanged(): void {
            notif.desktopEntry = notif.notification.desktopEntry;
            notif.normalizeIdentity();
        }

        function onImageChanged(): void {
            notif.image = notif.notification.image;
            notif.normalizeIdentity();
            notif.maybeTriggerDummyImageLoader();
        }

        function onExpireTimeoutChanged(): void {
            notif.expireTimeout = notif.notification.expireTimeout;
        }

        function onUrgencyChanged(): void {
            notif.urgency = notif.notification.urgency;
        }

        function onResidentChanged(): void {
            notif.resident = notif.notification.resident;
        }

        function onHasActionIconsChanged(): void {
            notif.hasActionIcons = notif.notification.hasActionIcons;
        }

        function onActionsChanged(): void {
            notif.actions = (notif.notification.actions as Array).map(a => ({
                        identifier: a.identifier,
                        text: a.text,
                        invoke: () => a.invoke()
                    }));
        }

        function onHintsChanged(): void {
            notif.hints = notif.notification.hints;
            notif.normalizeIdentity();
        }

        target: notif.notification
    }

    function updateTimeStr(): void {
        const diff = Date.now() - time.getTime();
        const m = Math.floor(diff / 60000);
        ageMins = m;

        if (m < 1) {
            timeStrTimer.interval = 5000;
        } else {
            const h = Math.floor(m / 60);
            const d = Math.floor(h / 24);

            if (d > 0)
                timeStrTimer.interval = 3600000;
            else if (h > 0)
                timeStrTimer.interval = 300000;
            else
                timeStrTimer.interval = m < 10 ? 30000 : 60000;
        }
    }

    function maybeTriggerDummyImageLoader(): void {
        if (image && !image.startsWith("image://icon/") && !image.startsWith(Paths.notifimagecache))
            dummyImageLoader.active = true;
    }

    // notify-send leaves application_name as "notify-send" and often ships the stock
    // dialog-information glyph. Prefer the .desktop identity when present, drop the
    // generic info art so Material "notifications" (or the real app icon) shows.
    function isGenericNotifySender(name: string): bool {
        const n = (name ?? "").trim().toLowerCase();
        return n === "notify-send" || n === "notify send" || n === "libnotify";
    }

    function isGenericInfoIcon(icon: string): bool {
        if (!icon)
            return false;
        const i = icon.toLowerCase();
        const base = i.replace(/^image:\/\/icon\//, "").split("/").pop().split(".")[0] ?? "";
        return ["dialog-information", "dialog-info", "dialog-question", "info", "gtk-dialog-info", "stock_dialog-info", "notification-information"].includes(base) || i.includes("dialog-information") || i.includes("dialog-info");
    }

    function normalizeIdentity(): void {
        const entryId = (desktopEntry || hints?.desktopEntry || "").replace(/\.desktop$/i, "");
        let entry = null;
        if (entryId)
            entry = DesktopEntries.byId(entryId) || DesktopEntries.byId(`${entryId}.desktop`);

        const fromNotifySend = notif.isGenericNotifySender(appName);
        useMaterialNotifIcon = fromNotifySend;

        if (entry && (fromNotifySend || !appName))
            appName = entry.name || appName;
        else if (fromNotifySend)
            appName = Tr.tr("Notification");

        // Drop the stock blue "i" (and similar) so Material / app icon can take over.
        if (notif.isGenericInfoIcon(image))
            image = "";

        if (entry && (!appIcon || notif.isGenericInfoIcon(appIcon)))
            appIcon = entry.icon || "";
        else if (notif.isGenericInfoIcon(appIcon))
            appIcon = "";
    }

    function lock(item: Item): void {
        locks.add(item);
    }

    function unlock(item: Item): void {
        locks.delete(item);
        if (closed)
            close();
    }

    function close(): void {
        closed = true;
        if (locks.size === 0 && Notifs.list.includes(this)) {
            Notifs.list = Notifs.list.filter(n => n !== this);
            notification?.dismiss();
            destroy();
        }
    }

    Component.onCompleted: {
        if (notification) {
            notificationId = notification.id;
            summary = notification.summary;
            body = notification.body;
            appIcon = notification.appIcon;
            appName = notification.appName;
            desktopEntry = notification.desktopEntry;
            image = notification.image;
            expireTimeout = notification.expireTimeout;
            hints = notification.hints;
            urgency = notification.urgency;
            resident = notification.resident;
            hasActionIcons = notification.hasActionIcons;

            actions = (notification.actions as Array).map(a => ({
                        identifier: a.identifier,
                        text: a.text,
                        invoke: () => a.invoke()
                    }));
        }

        normalizeIdentity();
        maybeTriggerDummyImageLoader();
    }
}
