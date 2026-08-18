import QtQuick
import qs.common.lib
import ".."

Column {
    id: root
    spacing: 0

    // Required properties from parent
    required property var ethernetDevice
    required property var deviceDetails
    required property int deviceSpeedMbps
    property bool reduced: false

    signal back()
    signal viewRoutes()

    NetworkPageHeader {
        width: parent.width
        // Show connection name if connected, device name, or just "Ethernet"
        title: root.ethernetDevice?.connection ?? root.ethernetDevice?.device ?? "Ethernet"
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
            value: root.ethernetDevice?.state === "connected" ? "Connected" : "Disconnected"
            valueColor: root.ethernetDevice?.state === "connected" ? Theme.colors.success : Theme.colors.textMuted
        }

        NetworkDetailRow {
            width: parent.width
            label: "Interface"
            value: root.ethernetDevice?.device ?? ""
            visible: !root.reduced
        }

        NetworkDetailRow {
            width: parent.width
            label: "Speed"
            value: Formatting.formatLinkSpeed(root.deviceSpeedMbps)
            visible: root.deviceSpeedMbps > 0
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

        // Properties section
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
    }
}
