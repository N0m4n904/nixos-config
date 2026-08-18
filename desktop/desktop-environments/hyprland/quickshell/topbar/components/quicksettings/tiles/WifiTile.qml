import QtQuick
import qs.common.lib
import qs.common.state
import ".."

QSTile {
    id: root

    colSpan: 4
    rowSpan: 2

    icon: active ? MaterialSymbols.wifi : MaterialSymbols.wifiOff
    label: "Wi-Fi"
    subtitle: {
        if (!hasWifiDevice) return "Unavailable"
        if (connectedNetwork) return connectedNetwork
        return "Off"
    }

    active: hasConnection
    enabled: hasWifiDevice

    readonly property var wifiDevices: NetworkState.devices.filter(d =>
        d.type === "wifi" &&
        d.state !== "unmanaged"
    )

    readonly property bool hasWifiDevice: wifiDevices.length > 0

    readonly property var connectedWifi: wifiDevices.find(d => d.state === "connected")

    readonly property bool hasConnection: connectedWifi !== undefined

    readonly property string connectedNetwork: {
        if (!connectedWifi) return ""
        return connectedWifi.connection || ""
    }

    onIconClick: {
        // Toggle WiFi via nmcli
        // TODO: implement wifi toggle
    }
    onClick: PanelManager.toggle(PanelManager.network)
}
