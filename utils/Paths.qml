pragma Singleton

import QtQuick
import Quickshell
import Sylphrena
import Sylphrena.Config

Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string pictures: Quickshell.env("XDG_PICTURES_DIR") || `${home}/Pictures`
    readonly property string videos: Quickshell.env("XDG_VIDEOS_DIR") || `${home}/Videos`

    readonly property string data: `${Quickshell.env("XDG_DATA_HOME") || `${home}/.local/share`}/sylphrena`
    readonly property string state: `${Quickshell.env("XDG_STATE_HOME") || `${home}/.local/state`}/sylphrena`
    readonly property string cache: `${Quickshell.env("XDG_CACHE_HOME") || `${home}/.cache`}/sylphrena`
    readonly property string config: `${Quickshell.env("XDG_CONFIG_HOME") || `${home}/.config`}/sylphrena`

    readonly property string imagecache: `${cache}/imagecache`
    readonly property string notifimagecache: `${imagecache}/notifs`
    readonly property string wallsdir: envVar("WALLPAPERS_DIR") || absolutePath(GlobalConfig.paths.wallpaperDir)
    // Spanish XDG videos folder + system Screenshots-style name (override with SYLPHRENA_RECORDINGS_DIR)
    readonly property string recsdir: envVar("RECORDINGS_DIR") || `${home}/Vídeos/Videocapturas de pantalla`
    readonly property string libdir: envVar("LIB_DIR") || `${home}/.local/lib`

    function envVar(name: string): string {
        return Quickshell.env(`SYLPHRENA_${name}`);
    }

    function toLocalFile(path: url): string {
        path = Qt.resolvedUrl(path);
        return path.toString() ? CUtils.toLocalFile(path) : "";
    }

    function absolutePath(path: string): string {
        return toLocalFile(path.replace(/~|(\$({?)HOME(}?))+/, home));
    }

    function shortenHome(path: string): string {
        return path.replace(home, "~");
    }
}
