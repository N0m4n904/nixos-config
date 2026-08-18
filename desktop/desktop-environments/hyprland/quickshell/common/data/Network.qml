pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property int sampleInterval: 2000

    // Interfaces whose traffic is either a duplicate of a physical link or noise from
    // a container/VPN stack, and would otherwise inflate the rate shown in the bar.
    readonly property var ignoredInterfaces: /^(lo|docker|veth|virbr|br-|tailscale|podman|vnet)/

    property real downstream: 0
    property real upstream: 0

    property real previousReceived: 0
    property real previousSent: 0
    property real previousTimestamp: 0

    function sample(contents) {
        let received = 0;
        let sent = 0;

        for (const line of contents.split("\n").slice(2)) {
            const columns = line.trim().split(/\s+/);
            const name = (columns[0] ?? "").replace(":", "");
            if (!name || ignoredInterfaces.test(name))
                continue;

            received += Number(columns[1]);
            sent += Number(columns[9]);
        }

        const timestamp = Date.now();
        const elapsed = (timestamp - previousTimestamp) / 1000;

        if (previousTimestamp > 0 && elapsed > 0) {
            downstream = Math.max(0, (received - previousReceived) / elapsed);
            upstream = Math.max(0, (sent - previousSent) / elapsed);
        }

        previousReceived = received;
        previousSent = sent;
        previousTimestamp = timestamp;
    }

    FileView {
        id: procNetDev

        path: "/proc/net/dev"
        onLoaded: root.sample(text())
    }

    Timer {
        interval: root.sampleInterval
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: procNetDev.reload()
    }
}
