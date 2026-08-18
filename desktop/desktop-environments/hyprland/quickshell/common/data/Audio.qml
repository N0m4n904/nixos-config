pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Singleton {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false

    function setVolume(level) {
        if (sink?.audio)
            sink.audio.volume = Math.max(0, Math.min(1, level));
    }

    function toggleMute() {
        if (sink?.audio)
            sink.audio.muted = !sink.audio.muted;
    }

    // Node properties stay unbound - and therefore meaningless - until something
    // tracks the node.
    PwObjectTracker {
        objects: [root.sink]
    }
}
