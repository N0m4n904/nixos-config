pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // Matches the GNOME Vitals extension's update-time of one second.
    readonly property int sampleInterval: 1000

    property real usage: 0

    function sample(contents) {
        const fields = {};
        for (const line of contents.split("\n")) {
            const field = line.match(/^(\w+):\s+(\d+)/);
            if (field)
                fields[field[1]] = Number(field[2]);
        }

        // MemAvailable already accounts for reclaimable cache, which is what "used"
        // should mean here - MemFree alone would report almost everything as used.
        if (fields.MemTotal > 0)
            usage = 1 - (fields.MemAvailable ?? 0) / fields.MemTotal;
    }

    FileView {
        id: procMeminfo

        path: "/proc/meminfo"
        onLoaded: root.sample(text())
    }

    Timer {
        interval: root.sampleInterval
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: procMeminfo.reload()
    }
}
