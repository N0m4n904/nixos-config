pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // Matches the GNOME Vitals extension's update-time of one second.
    readonly property int sampleInterval: 1000

    property real cpu: 0
    property real gpu: 0

    // Preference lists rather than fixed paths: hwmon numbering is not stable across
    // boots, and the same config should still find a sensor on other hardware. An
    // empty label matches the chip's first sensor.
    readonly property var cpuPreferences: [
        {
            chip: "k10temp",
            label: "Tctl"
        },
        {
            chip: "zenpower",
            label: "Tdie"
        },
        {
            chip: "coretemp",
            label: "Package id 0"
        },
        {
            chip: "k10temp",
            label: ""
        },
        {
            chip: "coretemp",
            label: ""
        }
    ]

    readonly property var gpuPreferences: [
        {
            chip: "amdgpu",
            label: "junction"
        },
        {
            chip: "amdgpu",
            label: "edge"
        },
        {
            chip: "amdgpu",
            label: ""
        },
        {
            chip: "nvidia",
            label: ""
        }
    ]

    readonly property string discoveryScript: 'for hwmon in /sys/class/hwmon/hwmon*; do ' + 'chip=$(cat "$hwmon/name" 2>/dev/null) || continue; ' + 'for input in "$hwmon"/temp*_input; do ' + '[ -e "$input" ] || continue; ' + 'printf "%s\\t%s\\t%s\\n" "$chip" "$(cat "${input%_input}_label" 2>/dev/null)" "$input"; ' + 'done; ' + 'done'

    property var sensors: []
    property string cpuPath: ""
    property string gpuPath: ""

    function resolve(preferences) {
        for (const preference of preferences) {
            const match = sensors.find(sensor => sensor.chip === preference.chip && (preference.label === "" || sensor.label === preference.label));
            if (match)
                return match.path;
        }
        return "";
    }

    Process {
        running: true
        command: ["sh", "-c", root.discoveryScript]

        stdout: SplitParser {
            onRead: line => {
                const [chip, label, path] = line.split("\t");
                if (path)
                    root.sensors = [...root.sensors, {
                            chip,
                            label,
                            path
                        }];
            }
        }

        onExited: {
            root.cpuPath = root.resolve(root.cpuPreferences);
            root.gpuPath = root.resolve(root.gpuPreferences);
        }
    }

    FileView {
        id: cpuSensor

        path: root.cpuPath
        onLoaded: root.cpu = Number(text()) / 1000
    }

    FileView {
        id: gpuSensor

        path: root.gpuPath
        onLoaded: root.gpu = Number(text()) / 1000
    }

    Timer {
        interval: root.sampleInterval
        running: true
        repeat: true
        onTriggered: {
            if (root.cpuPath)
                cpuSensor.reload();
            if (root.gpuPath)
                gpuSensor.reload();
        }
    }
}
