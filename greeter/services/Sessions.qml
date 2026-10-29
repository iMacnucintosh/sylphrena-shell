pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Wayland sessions offered by the greeter, parsed from the freedesktop session
// files. Only shown in the UI when there is more than one.
Singleton {
    id: root

    property list<var> entries: []
    property int index: 0

    readonly property var current: entries.length ? entries[Math.min(root.index, entries.length - 1)] : null
    readonly property bool multiple: entries.length > 1

    function select(i: int): void {
        root.index = i;
    }

    Component.onCompleted: proc.running = true

    Process {
        id: proc

        command: [
            "sh", "-c",
            `for f in /usr/share/wayland-sessions/*.desktop; do
  [ -f "$f" ] || continue
  grep -qE '^(Hidden|NoDisplay)=true' "$f" && continue
  n=$(sed -n 's/^Name=//p' "$f" | head -n1)
  e=$(sed -n 's/^Exec=//p' "$f" | head -n1)
  d=$(sed -n 's/^DesktopNames=//p' "$f" | head -n1)
  [ -n "$e" ] || continue
  printf '%s\\t%s\\t%s\\t%s\\n' "$f" "$n" "$e" "$d"
done`
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                const list = [];
                for (const line of text.trim().split("\n")) {
                    if (!line)
                        continue;
                    const [file, name, exec, desktop] = line.split("\t");
                    if (!exec)
                        continue;
                    const label = name || file.split("/").pop().replace(/\.desktop$/, "");
                    list.push({
                        file,
                        name: label,
                        exec,
                        desktop: desktop || ""
                    });
                }
                root.entries = list;
                const hyprland = list.findIndex(s => s.name === "Hyprland");
                root.index = hyprland >= 0 ? hyprland : 0;
                if (!list.length)
                    console.warn("greeter: no wayland sessions found");
            }
        }
    }
}
