pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // Network devices from nmcli
    property var devices: []

    // Primary device (has default route to internet)
    property string primaryDevice: ""

    Process {
        id: nmcliProcess
        command: ["jc", "nmcli", "device", "status"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.devices = JSON.parse(text)
                } catch (e) {
                    console.log("NetworkState: Failed to parse nmcli JSON:", e)
                    root.devices = []
                }
            }
        }
    }

    Process {
        id: ipRouteProcess
        command: ["jc", "ip", "route", "get", "8.8.8.8"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const routes = JSON.parse(text)
                    root.primaryDevice = routes[0]?.dev ?? ""
                } catch (e) {
                    root.primaryDevice = ""
                }
            }
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: {
            nmcliProcess.running = true
            ipRouteProcess.running = true
        }
    }

    // Convenience: refresh on demand
    function refresh() {
        nmcliProcess.running = true
        ipRouteProcess.running = true
    }
}
