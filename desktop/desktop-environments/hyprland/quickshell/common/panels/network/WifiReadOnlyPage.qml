import QtQuick
import qs.common.lib
import qs.common.panels

Column {
    id: root
    spacing: 0

    // Properties from parent
    property var wifiDevice: null
    property var connectedNetwork: null

    signal back()

    NetworkPageHeader {
        width: parent.width
        title: root.wifiDevice?.connection ?? root.wifiDevice?.device ?? "WiFi"
        onBack: root.back()
    }

    // Connected state
    Item {
        width: parent.width
        height: connectionStatus.height + 24
        visible: root.wifiDevice?.state === "connected" && !!root.connectedNetwork

        Column {
            id: connectionStatus
            anchors.centerIn: parent
            spacing: 8

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: MaterialSymbols.wifi
                color: Theme.colors.success
                font.pixelSize: 32
                font.family: Theme.iconFont
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Connected to " + (root.connectedNetwork?.ssid ?? "")
                color: Theme.colors.text
                font.pixelSize: 14
                font.weight: 500
            }

            // Connection details
            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 4

                NetworkDetailRow {
                    width: parent.width
                    label: "Signal"
                    value: (root.connectedNetwork?.signal ?? "0") + "%"
                }

                NetworkDetailRow {
                    width: parent.width
                    label: "Security"
                    value: root.connectedNetwork?.security || "Open"
                }
            }
        }
    }

    // Not connected state
    Item {
        width: parent.width
        height: notConnectedColumn.height + 24
        visible: root.wifiDevice?.state !== "connected" || !root.connectedNetwork

        Column {
            id: notConnectedColumn
            anchors.centerIn: parent
            spacing: 8

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: MaterialSymbols.wifiOff
                color: Theme.colors.textMuted
                font.pixelSize: 32
                font.family: Theme.iconFont
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Not connected to WiFi"
                color: Theme.colors.textMuted
                font.pixelSize: 14
                font.weight: 500
            }
        }
    }
}
