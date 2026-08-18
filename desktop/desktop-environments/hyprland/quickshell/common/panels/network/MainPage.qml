import QtQuick
import qs.common.lib

Column {
    id: root
    spacing: 0

    // All network devices (WiFi + Ethernet), sorted by connection status
    required property var devices
    // Device name of the primary gateway (from ip route)
    property string primaryDevice: ""

    signal deviceClicked(var device)

    // Header
    Text {
        text: "Network"
        color: Theme.colors.text
        font.pixelSize: 15
        font.weight: 600
        leftPadding: 4
        bottomPadding: 12
    }

    // Device list
    Repeater {
        model: root.devices

        Column {
            width: root.width

            // Separator between items (not before first)
            Rectangle {
                width: parent.width
                height: 1
                color: Theme.colors.separatorSubtle
                visible: index > 0
            }

            NetworkNavRow {
                width: parent.width
                icon: {
                    if (modelData.type === "wifi") {
                        return modelData.state === "connected" ? MaterialSymbols.wifi : MaterialSymbols.wifiOff
                    }
                    return modelData.state === "connected" ? MaterialSymbols.ethernet : MaterialSymbols.ethernetOff
                }
                iconColor: modelData.state === "connected" ? Theme.colors.accent : Theme.colors.textFaint
                // Use connection name if connected, otherwise use device name or type as fallback
                label: {
                    if (modelData.state === "connected" && modelData.connection) {
                        return modelData.connection
                    }
                    // Fallback: use device name or generic type name
                    const typeName = modelData.type === "wifi" ? "WiFi" : "Ethernet"
                    return modelData.device ?? typeName
                }
                status: modelData.state === "connected" ? "Connected" : "Disconnected"
                isPrimary: modelData.device === root.primaryDevice
                onClicked: root.deviceClicked(modelData)
            }
        }
    }

    // Empty state
    Item {
        width: parent.width
        height: 60
        visible: root.devices.length === 0

        Column {
            anchors.centerIn: parent
            spacing: 4

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: MaterialSymbols.wifiOff
                color: Theme.colors.textMuted
                font.pixelSize: 24
                font.family: Theme.iconFont
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "No network devices"
                color: Theme.colors.textMuted
                font.pixelSize: 12
            }
        }
    }
}
