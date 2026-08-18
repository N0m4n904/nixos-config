import QtQuick
import qs.common.lib
import ".."

Column {
    id: root
    spacing: 0

    // Required properties from parent
    required property var wifiDevice
    required property var deviceDetails
    required property int deviceSpeedMbps
    required property var connectedNetwork  // The network we're connected to (from wifi list)
    property bool reduced: false

    signal back()
    signal disconnect()
    signal viewRoutes()

    // Format security string
    function formatSecurity(security) {
        if (!security || security === "--" || security === "") return "Open"
        return security
    }

    NetworkPageHeader {
        width: parent.width
        title: root.connectedNetwork?.ssid ?? "WiFi"
        onBack: root.back()
    }

    // Device details
    Column {
        width: parent.width
        topPadding: 8
        spacing: 12

        NetworkDetailRow {
            width: parent.width
            label: "Status"
            value: root.wifiDevice?.state === "connected" ? "Connected" : "Disconnected"
            valueColor: root.wifiDevice?.state === "connected" ? Theme.colors.success : Theme.colors.textMuted
        }

        NetworkDetailRow {
            width: parent.width
            label: "Network"
            value: root.connectedNetwork?.ssid ?? root.wifiDevice?.connection ?? ""
        }

        NetworkDetailRow {
            width: parent.width
            label: "Security"
            value: root.formatSecurity(root.connectedNetwork?.security)
            visible: !!root.connectedNetwork?.security
        }

        NetworkDetailRow {
            width: parent.width
            label: "Signal"
            value: (root.connectedNetwork?.signal ?? "0") + "%"
            visible: !!root.connectedNetwork?.signal
        }

        NetworkDetailRow {
            width: parent.width
            label: "Band"
            value: Formatting.formatWifiBand(root.connectedNetwork?.freq)
            visible: !!Formatting.formatWifiBand(root.connectedNetwork?.freq)
        }

        NetworkDetailRow {
            width: parent.width
            label: "Channel"
            // GUESSED: channel field name might be 'chan' or 'channel'
            value: root.connectedNetwork?.chan ?? root.connectedNetwork?.channel ?? ""
            visible: !!(root.connectedNetwork?.chan ?? root.connectedNetwork?.channel)
        }

        NetworkDetailRow {
            width: parent.width
            label: "Frequency"
            // GUESSED: freq format, might need to append "MHz"
            value: {
                const freq = root.connectedNetwork?.freq
                if (!freq) return ""
                const freqStr = String(freq)
                return freqStr.includes("MHz") ? freqStr : freqStr + " MHz"
            }
            visible: !!root.connectedNetwork?.freq
        }

        NetworkDetailRow {
            width: parent.width
            label: "Speed"
            // GUESSED: rate format, might be "270 Mbit/s" or number
            value: {
                const rate = root.connectedNetwork?.rate
                if (!rate) return Formatting.formatLinkSpeed(root.deviceSpeedMbps)
                return String(rate)
            }
            visible: !!(root.connectedNetwork?.rate || root.deviceSpeedMbps > 0)
        }

        NetworkDetailRow {
            width: parent.width
            label: "Standard"
            value: Formatting.formatWifiGeneration(root.connectedNetwork?.freq, root.connectedNetwork?.rate)
            visible: !!Formatting.formatWifiGeneration(root.connectedNetwork?.freq, root.connectedNetwork?.rate)
        }

        NetworkDetailRow {
            width: parent.width
            label: "BSSID"
            value: root.connectedNetwork?.bssid ?? ""
            visible: !!root.connectedNetwork?.bssid
        }

        // Separator before IP details
        Rectangle {
            width: parent.width
            height: 1
            color: Theme.colors.separatorSubtle
            visible: !root.reduced && !!root.deviceDetails
        }

        NetworkDetailRow {
            width: parent.width
            label: "IPv4"
            value: root.deviceDetails?.ip4_address_1?.split("/")[0] ?? ""
            visible: !root.reduced && !!root.deviceDetails?.ip4_address_1
        }

        NetworkDetailRow {
            width: parent.width
            label: "IPv6"
            value: root.deviceDetails?.ip6_address_1?.split("/")[0] ?? ""
            visible: !root.reduced && !!root.deviceDetails?.ip6_address_1
        }

        NetworkDetailRow {
            width: parent.width
            label: "MAC"
            value: root.deviceDetails?.hwaddr ?? ""
            visible: !root.reduced && !!root.deviceDetails?.hwaddr
        }

        NetworkDetailRow {
            width: parent.width
            label: "Gateway"
            value: root.deviceDetails?.ip4_gateway ?? ""
            visible: !root.reduced && !!root.deviceDetails?.ip4_gateway
        }

        // Properties section (hidden in readOnly mode)
        Column {
            width: parent.width
            spacing: 0
            visible: !root.reduced

            SectionHeader { text: "Properties" }

            NetworkNavRow {
                width: parent.width
                icon: MaterialSymbols.route
                iconColor: Theme.colors.textSecondary
                label: "Routes"
                status: ""
                onClicked: root.viewRoutes()
            }
        }

        // Disconnect button (hidden in readOnly mode)
        Item {
            width: parent.width
            height: 48
            visible: root.wifiDevice?.state === "connected" && !root.reduced

            ActionButton {
                anchors.centerIn: parent
                width: parent.width - 16
                height: 36
                text: "Disconnect"
                variant: "danger"
                onClicked: root.disconnect()
            }
        }
    }
}
