pragma Singleton

import QtQuick
import Quickshell

// The app icons of the bar's desktops, one per window, so the bar can tell which window is under the pointer (a
// click layer covers them, so childAt cannot). Each icon registers itself and carries its `toplevel`.
Singleton {
    id: root

    property list<Item> icons: []

    function add(icon: Item): void {
        if (!root.icons.includes(icon))
            root.icons = [...root.icons, icon];
    }

    function remove(icon: Item): void {
        root.icons = root.icons.filter(i => i !== icon);
    }

    // The icon (of `item`'s window) under the point x, y of `item`, or null
    function at(item: Item, x: real, y: real): Item {
        for (const icon of root.icons) {
            if (!icon || !icon.visible || icon.opacity <= 0)
                continue;
            const p = item.mapToItem(icon, x, y);
            if (p.x >= 0 && p.y >= 0 && p.x <= icon.width && p.y <= icon.height)
                return icon;
        }
        return null;
    }
}
