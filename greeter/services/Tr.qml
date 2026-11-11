pragma Singleton

import Quickshell
import Quickshell.Io

// Translations of the login screen: the code is in English and greeter/i18n/<lang>.json maps English → the
// language of the system (LC_ALL / LC_MESSAGES / LANG). The greeter does not use the shell's plugin, which the
// greeter user could not read from a user-local install, so it has this small catalogue of its own.
Singleton {
    id: root

    property var catalog: ({})

    readonly property string lang: {
        for (const name of ["LC_ALL", "LC_MESSAGES", "LANG"]) {
            const v = Quickshell.env(name) ?? "";
            if (v && v !== "C" && v !== "POSIX")
                return v.split(/[_.@]/)[0];
        }
        return "";
    }

    function tr(text: string): string {
        return root.catalog[text] ?? text;
    }

    FileView {
        path: root.lang ? `${Quickshell.shellDir}/i18n/${root.lang}.json` : ""
        blockLoading: true
        printErrors: false
        onLoaded: {
            try {
                root.catalog = JSON.parse(text());
            } catch (e) {
                root.catalog = {};
            }
        }
    }
}
