import QtQuick
import Quickshell.Services.Pipewire
import qs.common.lib

QSSlider {
    id: root

    colSpan: 8
    rowSpan: 1

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool isMuted: sink?.audio?.muted ?? false

    PwObjectTracker {
        objects: [root.sink]
    }

    icon: {
        if (isMuted) return MaterialSymbols.volumeOff
        if (volume < 0.01) return MaterialSymbols.volumeMute
        if (volume < 0.5) return MaterialSymbols.volumeDown
        return MaterialSymbols.volumeUp
    }
    iconMax: MaterialSymbols.volumeUp

    value: volume
    minValue: 0.0
    maxValue: 1.0
    muted: isMuted

    onAdjusted: function(newValue) {
        if (sink?.audio) {
            sink.audio.volume = newValue
        }
    }

    onClicked: {
        if (sink?.audio) {
            sink.audio.muted = !sink.audio.muted
        }
    }
}
