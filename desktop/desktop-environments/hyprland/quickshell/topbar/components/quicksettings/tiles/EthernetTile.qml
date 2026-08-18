import QtQuick
import qs.common.lib
import qs.common.state
import ".."

QSTile {
    id: root

    colSpan: 4
    rowSpan: 2
    visible: hasEthernetDevice

    icon: active ? MaterialSymbols.ethernet : MaterialSymbols.ethernetOff
    label: "Ethernet"
    subtitle: {
        if (!hasEthernetDevice) return "Unavailable"
        if (connectedName) return connectedName
        return "Disconnected"
    }

    active: hasConnection
    enabled: hasEthernetDevice

    readonly property var ethernetDevices: NetworkState.devices.filter(d =>
        d.type === "ethernet" &&
        d.state !== "unmanaged" &&
        !d.device.startsWith("veth") &&
        !d.device.startsWith("br-") &&
        !d.device.startsWith("docker")
    )

    readonly property bool hasEthernetDevice: ethernetDevices.length > 0

    readonly property var connectedEthernet: ethernetDevices.find(d => d.state === "connected")

    readonly property bool hasConnection: connectedEthernet !== undefined

    readonly property string connectedName: {
        if (!connectedEthernet) return ""
        return connectedEthernet.connection || "Connected"
    }

    onClick: PanelManager.toggle(PanelManager.network)
}
