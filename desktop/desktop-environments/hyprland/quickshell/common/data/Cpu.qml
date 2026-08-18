pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // Matches the GNOME Vitals extension's update-time of one second.
    readonly property int sampleInterval: 1000

    property real usage: 0

    // Average across cores, in GHz. /proc/cpuinfo carries every core's current clock
    // in one file, where /sys/.../scaling_cur_freq would be a read per core.
    property real frequency: 0

    function sampleFrequency(contents) {
        const clocks = contents.split("\n").filter(line => line.startsWith("cpu MHz")).map(line => Number(line.split(":")[1]));

        if (clocks.length > 0)
            frequency = clocks.reduce((sum, value) => sum + value, 0) / clocks.length / 1000;
    }

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

    FileView {
        id: procCpuinfo

        path: "/proc/cpuinfo"
        onLoaded: root.sampleFrequency(text())
    }

    Timer {
        interval: root.sampleInterval
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            procStat.reload();
            procCpuinfo.reload();
        }
    }
}
