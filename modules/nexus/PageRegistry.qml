pragma Singleton

import QtQuick
import Caelestia.I18n

QtObject {
    id: root

    function idxOf(pageId: string): int {
        for (let i = 0; i < root.pages.length; i++)
            if (root.pages[i].id === pageId)
                return i;
        return -1;
    }

    readonly property list<var> pages: [
        // Appearance
        {
            id: "activities",
            label: Tr.tr("Activities"),
            icon: "dashboard_customize",
            description: Tr.tr("Behaviour, shortcuts and the unified look (general and per-activity)"),
            category: "appearance"
        },

        // Connectivity
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
            description: Tr.tr("Bluetooth, pairing"),
            category: "connectivity",
            noFill: true
        },
        {
            id: "display",
            label: Tr.trCtx("Display", "monitor settings"),
            icon: "monitor",
            description: Tr.tr("Output modes, scale, adaptive sync (VRR)"),
            category: "connectivity"
        },
        {
            id: "audio",
            label: Tr.tr("Audio"),
            icon: "volume_up",
            description: Tr.tr("App volumes, sound devices"),
            category: "connectivity"
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
            id: "complements",
            label: Tr.tr("Complements"),
            icon: "extension",
            description: Tr.tr("Optional fork features (VPN, clipboard, Steam, …)"),
            category: "system"
        },

        // Shell
        {
            id: "panels",
            label: Tr.tr("Panels"),
            icon: "dock_to_bottom",
            description: Tr.tr("Dashboard, taskbar, launcher, sidebar"),
            category: "shell"
        },
        {
            id: "apps",
            label: Tr.tr("Apps"),
            icon: "apps",
            description: Tr.tr("Default apps, favourites, hidden apps"),
            category: "shell"
        },
        {
            id: "services",
            label: Tr.tr("Services"),
            icon: "build",
            description: Tr.tr("Poll intervals, lyrics backend"),
            category: "shell"
        },
        {
            id: "language",
            label: Tr.tr("Language & region"),
            icon: "globe",
            description: Tr.tr("UI language, weather location, display units"),
            category: "shell"
        },
        {
            id: "keybinds",
            label: Tr.tr("Keyboard & mouse"),
            icon: "keyboard",
            description: Tr.tr("Shell shortcuts and remapping"),
            category: "shell"
        },

        // About
        {
            id: "about",
            label: Tr.tr("About"),
            icon: "info",
            description: Tr.tr("System information, credits"),
            category: "about"
        },
    ]
}
