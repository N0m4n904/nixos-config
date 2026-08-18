pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property int sampleInterval: 2000

    property real usage: 0

    // /proc/stat counts jiffies since boot, so utilisation is only meaningful as the
    // delta between two samples.
    property real previousIdle: 0
    property real previousTotal: 0

    function sample(contents) {
        const jiffies = contents.split("\n")[0].trim().split(/\s+/).slice(1).map(Number);
        if (jiffies.length < 5)
            return;

        const idle = jiffies[3] + jiffies[4];
        const total = jiffies.reduce((sum, value) => sum + value, 0);
        const elapsed = total - previousTotal;

        if (previousTotal > 0 && elapsed > 0)
            usage = Math.max(0, Math.min(1, 1 - (idle - previousIdle) / elapsed));

        previousIdle = idle;
        previousTotal = total;
    }

    FileView {
        id: procStat

        path: "/proc/stat"
        onLoaded: root.sample(text())
    }

    Timer {
        interval: root.sampleInterval
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: procStat.reload()
    }
}
