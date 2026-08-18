import QtQuick
import Quickshell.Io
import qs.common.lib

QSSlider {
    id: root

    colSpan: 8
    rowSpan: 1
    visible: available

    icon: MaterialSymbols.brightnessLow
    iconMax: MaterialSymbols.brightnessHigh

    value: brightnessValue
    minValue: 0.0
    maxValue: 1.0

    property real brightnessValue: 1.0
    property bool available: false

    onAdjusted: function(newValue) {
        brightnessValue = newValue
        const percent = Math.round(newValue * 100)
        setBrightnessProcess.command = ["brightnessctl", "set", percent + "%"]
        setBrightnessProcess.running = true
    }

    // Read current brightness on load
    Component.onCompleted: {
        getBrightnessProcess.running = true
    }

    Process {
        id: getBrightnessProcess
        command: ["brightnessctl", "info", "-m"]
        stdout: SplitParser {
            onRead: data => {
                // Format: device,class,current,percentage%,max
                const parts = data.split(",")
                if (parts.length >= 4) {
                    root.available = true
                    const percentStr = parts[3].replace("%", "")
                    const percent = parseInt(percentStr)
                    if (!isNaN(percent)) {
                        root.brightnessValue = percent / 100.0
                    }
                }
            }
        }
    }

    Process {
        id: setBrightnessProcess
        command: ["brightnessctl", "set", "100%"]
    }

    // Refresh brightness periodically (in case changed externally)
    Timer {
        interval: 5000
        running: root.available
        repeat: true
        onTriggered: getBrightnessProcess.running = true
    }
}
