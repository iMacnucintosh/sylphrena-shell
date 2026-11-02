pragma Singleton

import QtQml
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import Sylphrena
import Sylphrena.Config
import Sylphrena.I18n
import qs.components.misc

Singleton {
    id: root

    readonly property list<MprisPlayer> list: Mpris.players.values
    readonly property MprisPlayer active: props.manualActive ?? list.find(p => getIdentity(p) === GlobalConfig.services.defaultPlayer) ?? list[0] ?? null
    property alias manualActive: props.manualActive

    // Dedup key for progressive metadata (e.g. mpv-mpris/yt-dlp player fills title then artist later).
    property string lastNowPlayingKey: ""

    function getIdentity(player: MprisPlayer): string {
        if (!player)
            return "";
        const alias = GlobalConfig.services.playerAliases.values.find(a => a.from === player.identity);
        return alias?.to ?? player.identity;
    }

    function getArtUrl(player: MprisPlayer): string {
        if (!player)
            return "";
        const url = `${player.metadata["xesam:url"] ?? ""}`;
        // Prefer YouTube CDN thumbs (watch / shorts / live / youtu.be) over the
        // browser's local mpris cache, which is often a small cropped frame.
        const ytId = url.match(/(?:[?&]v=|youtu\.be\/|\/(?:shorts|live)\/)([\w-]{11})/)?.[1];
        if (ytId)
            return `https://img.youtube.com/vi/${ytId}/hqdefault.jpg`;
        return player.trackArtUrl || "";
    }

    // YouTube muted autoplay previews (search/home/feed) keep the listing page in
    // xesam:url; a real play switches to /watch|/shorts|/live. MPRIS Volume stays 1
    // for HTML5-muted media, so volume alone cannot detect those previews.
    function isListingPreview(player: MprisPlayer): bool {
        const url = `${player.metadata["xesam:url"] ?? ""}`;
        if (!/youtube\.com\//i.test(url))
            return false;
        return !/\/(watch|shorts|live)\b/i.test(url);
    }

    // Quickshell only emits postTrackChanged when trackid/url/title change, so late
    // artist updates (common with mpv-mpris + yt-dlp player) never retrigger it. Watch
    // title/artist too and toast once both are usable.
    function maybeToastNowPlaying(): void {
        if (!GlobalConfig.utilities.toasts.nowPlaying)
            return;

        const player = root.active;
        if (!player)
            return;

        // Soft-mute when the player reports it (Spotify etc.). Do not record the key:
        // unmuting / opening the real watch URL should still be allowed to toast.
        if ((player.volumeSupported && player.volume <= 0) || root.isListingPreview(player))
            return;

        const title = player.trackTitle ?? "";
        const artist = player.trackArtist ?? "";
        if (!title || !artist)
            return;

        // No uniqueId: Zen/Firefox rebind MPRIS on focus (new id) and would re-toast.
        const key = `${getIdentity(player)}\0${title}\0${artist}`;
        if (key === lastNowPlayingKey)
            return;

        lastNowPlayingKey = key;
        Toaster.toast(Tr.tr("Now playing"), Tr.trCtx("%1 - %2", "track artist and title").arg(artist).arg(title), "music_note", Toast.Info, 5000, root.getArtUrl(player));
    }

    // lastNowPlayingKey survives activeChanged: browser MPRIS rebinds on focus.

    Connections {
        function onPostTrackChanged(): void {
            root.maybeToastNowPlaying();
        }

        function onTrackTitleChanged(): void {
            root.maybeToastNowPlaying();
        }

        function onTrackArtistChanged(): void {
            root.maybeToastNowPlaying();
        }

        function onVolumeChanged(): void {
            root.maybeToastNowPlaying();
        }

        target: root.active
    }

    PersistentProperties {
        id: props

        property MprisPlayer manualActive

        reloadableId: "players"
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "mediaToggle"
        description: "Toggle media playback"
        onPressed: {
            const active = root.active;
            if (active && active.canTogglePlaying)
                active.togglePlaying();
        }
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "mediaPrev"
        description: "Previous track"
        onPressed: {
            const active = root.active;
            if (active && active.canGoPrevious)
                active.previous();
        }
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "mediaNext"
        description: "Next track"
        onPressed: {
            const active = root.active;
            if (active && active.canGoNext)
                active.next();
        }
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "mediaStop"
        description: "Stop media playback"
        onPressed: root.active?.stop()
    }

    IpcHandler {
        function getActive(prop: string): string {
            const active = root.active;
            return active ? active[prop] ?? "Invalid property" : "No active player";
        }

        function list(): string {
            return root.list.map(p => root.getIdentity(p)).join("\n");
        }

        function play(): void {
            const active = root.active;
            if (active?.canPlay)
                active.play();
        }

        function pause(): void {
            const active = root.active;
            if (active?.canPause)
                active.pause();
        }

        function playPause(): void {
            const active = root.active;
            if (active?.canTogglePlaying)
                active.togglePlaying();
        }

        function previous(): void {
            const active = root.active;
            if (active?.canGoPrevious)
                active.previous();
        }

        function next(): void {
            const active = root.active;
            if (active?.canGoNext)
                active.next();
        }

        function stop(): void {
            root.active?.stop();
        }

        target: "mpris"
    }
}
