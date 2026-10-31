pragma Singleton

import QtQuick
import Sylphrena.I18n

QtObject {
    id: root

    function idxOf(pageId: string): int {
        for (let i = 0; i < root.pages.length; i++)
            if (root.pages[i].id === pageId)
                return i;
        return -1;
    }

    function categoryLabel(category: string): string {
        switch (category) {
        case "appearance":
            return Tr.tr("Desktop & appearance");
        case "input":
            return Tr.tr("Input");
        case "connectivity":
            return Tr.tr("Devices");
        case "apps":
            return Tr.trCtx("Apps", "nexus sidebar category");
        case "system":
            return Tr.tr("System");
        case "about":
            return Tr.trCtx("About", "nexus sidebar category");
        default:
            return category;
        }
    }

    readonly property list<var> pages: [
        // Desktop & appearance
        {
            id: "activities",
            label: Tr.tr("Activities"),
            icon: "dashboard_customize",
            description: Tr.tr("Behaviour, shortcuts and the unified look (general and per-activity)"),
            category: "appearance"
        },
        {
            id: "panels",
            label: Tr.tr("Panels"),
            icon: "dock_to_bottom",
            description: Tr.tr("Dashboard, taskbar, launcher, sidebar"),
            category: "appearance"
        },
        {
            id: "complements",
            label: Tr.tr("Complements"),
            icon: "extension",
            description: Tr.tr("Optional fork features (VPN, clipboard, Steam, …)"),
            category: "appearance"
        },

        // Input
        {
            id: "keybinds",
            label: Tr.tr("Keyboard & mouse"),
            icon: "keyboard",
            description: Tr.tr("Shortcuts, remappings"),
            category: "input"
        },

        // Devices (Display lives inside Connected devices as a subpage)
        {
            id: "network",
            label: Tr.tr("Network"),
            icon: "wifi",
            description: Tr.tr("Wi-Fi, ethernet, VPN"),
            category: "connectivity"
        },
        {
            id: "bluetooth",
            label: Tr.tr("Connected devices"),
            icon: "devices_other",
            description: Tr.tr("Bluetooth, pairing, displays"),
            category: "connectivity",
            noFill: true
        },
        {
            id: "audio",
            label: Tr.tr("Audio"),
            icon: "volume_up",
            description: Tr.tr("Output, input"),
            category: "connectivity"
        },

        // Apps
        {
            id: "apps",
            label: Tr.tr("Apps"),
            icon: "apps",
            description: Tr.tr("Defaults, library"),
            category: "apps"
        },

        // System
        {
            id: "updates",
            label: Tr.tr("Updates"),
            icon: "autorenew",
            description: Tr.tr("System updates"),
            category: "system"
        },
        {
            id: "language",
            label: Tr.tr("Language & region"),
            icon: "globe",
            description: Tr.tr("Location, units"),
            category: "system"
        },
        {
            // Stable id "services" (was Tuning hub); root page is Notifications.
            id: "services",
            label: Tr.tr("Notifications"),
            icon: "notifications",
            description: Tr.tr("Categories, toasts"),
            category: "system"
        },

        // About
        {
            id: "about",
            label: Tr.tr("System information"),
            icon: "info",
            description: Tr.tr("Versions, hardware, software"),
            category: "about"
        },
    ]
}
