pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Singleton {
    id: root

    readonly property var players: Mpris.players?.values ?? []

    // A player that is actually playing outranks one that merely exists, so the bar
    // follows whatever is making noise rather than whichever client registered first.
    readonly property var player: players.find(candidate => candidate.isPlaying) ?? players[0] ?? null

    readonly property bool available: player !== null
    readonly property bool playing: player?.isPlaying ?? false
    readonly property string title: player?.trackTitle ?? ""
    readonly property string artist: player?.trackArtist ?? ""
    readonly property string artUrl: player?.trackArtUrl ?? ""

    readonly property bool canGoNext: player?.canGoNext ?? false
    readonly property bool canGoPrevious: player?.canGoPrevious ?? false
    readonly property bool loopSupported: player?.loopSupported ?? false
    readonly property bool shuffleSupported: player?.shuffleSupported ?? false
    readonly property bool shuffle: player?.shuffle ?? false

    readonly property string loopState: {
        switch (player?.loopState) {
        case MprisLoopState.Track:
            return "track";
        case MprisLoopState.Playlist:
            return "playlist";
        default:
            return "none";
        }
    }

    function togglePlaying() {
        if (player?.canTogglePlaying)
            player.togglePlaying();
    }

    function next() {
        if (canGoNext)
            player.next();
    }

    function previous() {
        if (canGoPrevious)
            player.previous();
    }

    function cycleLoop() {
        if (!loopSupported)
            return;

        switch (player.loopState) {
        case MprisLoopState.None:
            player.loopState = MprisLoopState.Playlist;
            break;
        case MprisLoopState.Playlist:
            player.loopState = MprisLoopState.Track;
            break;
        default:
            player.loopState = MprisLoopState.None;
        }
    }

    function toggleShuffle() {
        if (shuffleSupported)
            player.shuffle = !player.shuffle;
    }
}
