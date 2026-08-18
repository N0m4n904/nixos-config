import QtQuick
import QtQuick.Controls
import qs.common.lib
import ".."

Column {
    id: root
    spacing: 0

    // Properties from parent
    property var wifiDevice: null
    property var wifiNetworks: []
    property bool scanning: false
    property bool connecting: false
    property string connectionError: ""

    signal back()
    signal scanRequested()
    signal networkSelected(var network)
    signal connectRequested(string ssid, string password)
    signal viewDetails()

    // Find the currently connected network from the list
    readonly property var connectedNetwork: wifiNetworks?.find(n => n.in_use === "*") ?? null

    // Filter and sort networks: connected first, then by signal strength
    readonly property var sortedNetworks: {
        if (!wifiNetworks) return []
        const networks = wifiNetworks.slice()
        networks.sort((a, b) => {
            // Connected network first
            if (a.in_use === "*") return -1
            if (b.in_use === "*") return 1
            // Then by signal strength (descending)
            const signalA = parseInt(a.signal) || 0
            const signalB = parseInt(b.signal) || 0
            return signalB - signalA
        })
        // Remove duplicates by SSID (keep the one with strongest signal)
        const seen = new Set()
        return networks.filter(n => {
            const ssid = n.ssid || ""
            if (!ssid || seen.has(ssid)) return false
            seen.add(ssid)
            return true
        })
    }

    NetworkPageHeader {
        width: parent.width
        // Show connection name if connected, device name, or just "WiFi"
        title: root.wifiDevice?.connection ?? root.wifiDevice?.device ?? "WiFi"
        onBack: root.back()
    }

    // Current connection status (if connected)
    Item {
        width: parent.width
        height: connectionStatus.height + 16
        visible: root.wifiDevice?.state === "connected" && !!root.connectedNetwork

        Column {
            id: connectionStatus
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4

            Row {
                spacing: 8

                Text {
                    text: MaterialSymbols.check
                    color: Theme.colors.success
                    font.pixelSize: 16
                    font.family: Theme.iconFont
                }

                Text {
                    text: "Connected to " + (root.connectedNetwork?.ssid ?? "")
                    color: Theme.colors.text
                    font.pixelSize: 13
                    font.weight: 500
                }
            }

            // Tap to view details
            Rectangle {
                width: viewDetailsRow.width + 16
                height: 24
                radius: 12
                color: viewDetailsHover.hovered ? Theme.colors.hover : "transparent"

                Behavior on color { ColorAnimation { duration: Theme.duration.fast } }

                Row {
                    id: viewDetailsRow
                    anchors.centerIn: parent
                    spacing: 4

                    Text {
                        text: "View Details"
                        color: Theme.colors.accent
                        font.pixelSize: 11
                        font.weight: 500
                    }

                    Text {
                        text: MaterialSymbols.chevronRight
                        color: Theme.colors.accent
                        font.pixelSize: 14
                        font.family: Theme.iconFont
                    }
                }

                HoverHandler {
                    id: viewDetailsHover
                    cursorShape: Qt.PointingHandCursor
                }

                TapHandler {
                    onTapped: root.viewDetails()
                }
            }
        }
    }

    // Separator
    Rectangle {
        width: parent.width
        height: 1
        color: Theme.colors.separatorSubtle
        visible: root.wifiDevice?.state === "connected" && !!root.connectedNetwork
    }

    // Connection error message
    ErrorMessage {
        width: parent.width
        height: 32
        message: root.connectionError
    }

    // Available networks header
    Item {
        width: parent.width
        height: 32

        FieldLabel {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: "Available Networks"
        }

        // Scan spinner/button
        Item {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: 24
            height: 24

            Text {
                anchors.centerIn: parent
                text: MaterialSymbols.refresh
                color: Theme.colors.textMuted
                font.pixelSize: 18
                font.family: Theme.iconFont
                opacity: root.scanning ? 0.5 : (scanHover.hovered ? 1 : 0.8)

                Behavior on opacity { NumberAnimation { duration: Theme.duration.fast } }

                RotationAnimation on rotation {
                    running: root.scanning
                    from: 0
                    to: 360
                    duration: 1000
                    loops: Animation.Infinite
                }
            }

            HoverHandler {
                id: scanHover
                cursorShape: Qt.PointingHandCursor
            }

            TapHandler {
                enabled: !root.scanning
                onTapped: root.scanRequested()
            }
        }
    }

    // Network list
    Column {
        width: parent.width
        spacing: 0

        Repeater {
            // Show up to 10 networks
            model: root.sortedNetworks.slice(0, 10)

            delegate: WifiNetworkRow {
                required property var modelData
                required property int index
                width: parent.width
                network: modelData
                onClicked: root.networkSelected(modelData)
            }
        }

        // Empty state
        Item {
            width: parent.width
            height: 60
            visible: root.sortedNetworks.length === 0 && !root.scanning

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
                    text: "No networks found"
                    color: Theme.colors.textMuted
                    font.pixelSize: 12
                }
            }
        }

        // Loading state
        Item {
            width: parent.width
            height: 60
            visible: root.scanning && root.sortedNetworks.length === 0

            Column {
                anchors.centerIn: parent
                spacing: 4

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: MaterialSymbols.wifi
                    color: Theme.colors.textMuted
                    font.pixelSize: 24
                    font.family: Theme.iconFont

                    SequentialAnimation on opacity {
                        running: root.scanning
                        loops: Animation.Infinite
                        NumberAnimation { to: 0.3; duration: 500 }
                        NumberAnimation { to: 1; duration: 500 }
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Scanning..."
                    color: Theme.colors.textMuted
                    font.pixelSize: 12
                }
            }
        }

        // Connecting state overlay
        Item {
            width: parent.width
            height: 40
            visible: root.connecting

            Row {
                anchors.centerIn: parent
                spacing: 8

                Text {
                    text: MaterialSymbols.wifi
                    color: Theme.colors.accent
                    font.pixelSize: 18
                    font.family: Theme.iconFont

                    SequentialAnimation on opacity {
                        running: root.connecting
                        loops: Animation.Infinite
                        NumberAnimation { to: 0.3; duration: 400 }
                        NumberAnimation { to: 1; duration: 400 }
                    }
                }

                Text {
                    text: "Connecting..."
                    color: Theme.colors.textMuted
                    font.pixelSize: 12
                }
            }
        }
    }
}
