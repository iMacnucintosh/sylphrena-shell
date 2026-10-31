pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Sylphrena
import Sylphrena.I18n
import qs.utils

// System file picker via Seeker (--pick). Keeps the old FloatingWindow API.
Item {
    id: loader

    property list<string> cwd: ["Home"]
    property string filterLabel: Tr.tr("All files")
    property list<string> filters: ["*"]
    property string title: Tr.tr("Select a file")

    signal accepted(path: string)
    signal rejected

    property bool busy: false
    property string resultPath: ""

    function cwdAbsolute(): string {
        if (!cwd.length || cwd[0] === "Home") {
            const rest = cwd.slice(1).join("/");
            return rest.length ? `${Paths.home}/${rest}` : Paths.home;
        }
        return cwd.join("/");
    }

    function open(): void {
        if (busy)
            return;
        busy = true;
        const runtime = Quickshell.env("XDG_RUNTIME_DIR") || "/tmp";
        resultPath = `${runtime}/seeker-pick-${Date.now()}.json`;
        pickProc.running = false;
        Qt.callLater(() => {
            pickProc.running = true;
        });
    }

    function close(): void {
        pickProc.running = false;
        if (busy) {
            busy = false;
            rejected();
        }
    }

    function finishFromResult(): void {
        const path = loader.resultPath;
        loader.resultPath = "";
        loader.busy = false;

        let response = 1;
        let uris = [];
        try {
            const raw = resultView.text();
            if (raw && raw.length) {
                const data = JSON.parse(raw);
                response = data.response ?? 1;
                uris = data.uris ?? [];
            }
        } catch (e) {
            response = 1;
        }
        CUtils.deleteFile(Qt.resolvedUrl(path));

        if (response === 0 && uris.length) {
            let filePath = uris[0];
            if (filePath.startsWith("file://"))
                filePath = decodeURIComponent(filePath.slice("file://".length));
            const exts = loader.filters.filter(f => f && f !== "*").map(f => f.toLowerCase());
            if (exts.length) {
                const lower = filePath.toLowerCase();
                if (!exts.some(ext => lower.endsWith(`.${ext}`))) {
                    loader.rejected();
                    return;
                }
            }
            loader.accepted(filePath);
        } else {
            loader.rejected();
        }
    }

    Process {
        id: pickProc

        command: {
            const bin = `${Paths.home}/.local/bin/seeker`;
            const args = [
                bin,
                "--pick",
                "--pick-mode=file",
                `--pick-result=${loader.resultPath}`,
                `--pick-title=${loader.title}`,
                `--pick-accept=${Tr.tr("Select")}`,
                `--pick-current=${loader.cwdAbsolute()}`
            ];
            const exts = loader.filters.filter(f => f && f !== "*").map(f => f.toLowerCase());
            if (exts.length)
                args.push(`--pick-extensions=${exts.join(",")}`);
            return args;
        }

        onExited: {
            if (!loader.resultPath.length) {
                loader.busy = false;
                loader.rejected();
                return;
            }
            resultView.path = loader.resultPath;
            resultView.reload();
        }
    }

    FileView {
        id: resultView
        printErrors: false
        onLoaded: loader.finishFromResult()
        onLoadFailed: loader.finishFromResult()
    }
}
