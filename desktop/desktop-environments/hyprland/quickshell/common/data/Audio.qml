pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Singleton {
    id: root

    readonly property var nodes: Pipewire.nodes?.values ?? []

    // Devices, not the per-application streams playing through them. The GoXLR's
    // routing channels only appear here while its daemon is running.
    readonly property var sinks: nodes.filter(node => node.isSink && !node.isStream)
    readonly property var streams: nodes.filter(node => node.isStream && !node.isSink)

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

    function setNodeVolume(node, level) {
        if (node?.audio)
            node.audio.volume = Math.max(0, Math.min(1, level));
    }

    function toggleNodeMute(node) {
        if (node?.audio)
            node.audio.muted = !node.audio.muted;
    }

    function makeDefault(node) {
        Pipewire.preferredDefaultAudioSink = node;
    }

    function label(node) {
        return node?.description || node?.nickname || node?.name || "";
    }

    function streamLabel(node) {
        const properties = node?.properties ?? {};
        return properties["application.name"] || properties["media.name"] || label(node);
    }

    // Volume and mute are meaningless on an untracked node, and the panel reads them
    // for every device and stream it lists, not just the default one.
    PwObjectTracker {
        objects: [root.sink, ...root.sinks, ...root.streams]
    }
}
