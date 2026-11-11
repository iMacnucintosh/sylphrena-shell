pragma Singleton

import Quickshell
import Quickshell.Io
import Sylphrena.I18n
import qs.services

// Connects kitty to the shell's colours the first time the shell runs with kitty installed
// (scripts/setup-kitty.py: the template, and a marked block in kitty.conf; idempotent, once). Tells the
// user when it changed something.
Singleton {
    id: root

    Process {
        running: true
        command: ["python3", Quickshell.shellPath("scripts/setup-kitty.py")]
        stdinEnabled: false
        stdout: StdioCollector {
            onStreamFinished: {
                let r = null;
                try {
                    r = JSON.parse(text);
                } catch (e) {
                    return;
                }
                if (r?.status !== "done" || !(r.changed ?? []).includes("kitty.conf"))
                    return;
                Toaster.toast(Tr.tr("kitty now follows your colours"), Tr.tr("Sylphrena added a block to your kitty.conf (a backup is next to it). Remove the block to disconnect it."), "terminal");
            }
        }
    }
}
