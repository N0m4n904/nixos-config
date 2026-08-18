import QtQuick
import qs.common.lib

Rectangle {
    id: root
    height: 52
    color: hoverHandler.hovered ? Theme.colors.hover : "transparent"
    radius: 6

    // Network data from nmcli wifi list (terse mode)
    // Fields: ssid, bssid, signal, security, freq, rate, chan, in_use, mode
    required property var network

    property bool isConnected: network?.in_use === "*"

    signal clicked()

    Behavior on color { ColorAnimation { duration: Theme.duration.fast } }

    // Helper function to determine band from frequency
    // freq is numeric string (e.g., "2437" or "5680")
    function getBand(freq) {
        if (!freq) return ""
        const freqNum = typeof freq === "string" ? parseInt(freq) : freq
        if (freqNum >= 2400 && freqNum < 2500) return "2.4G"
        if (freqNum >= 5150 && freqNum < 5900) return "5G"
        if (freqNum >= 5925 && freqNum < 7125) return "6G"
        return ""
    }

    // Helper function to infer WiFi generation
    // This is an approximation based on rate and frequency
    // Cannot be accurately determined from nmcli output alone
    function getWifiGeneration(freq, rate) {
        if (!freq || !rate) return ""
        const freqNum = typeof freq === "string" ? parseInt(freq) : freq
        // rate is numeric string (e.g., "130" or "1170")
        const rateNum = typeof rate === "string" ? parseInt(rate) : rate

        // 6 GHz band is WiFi 6E or WiFi 7
        if (freqNum >= 5925) {
            return rateNum > 2000 ? "WiFi 7" : "WiFi 6E"
        }
        // 5 GHz band
        if (freqNum >= 5000) {
            if (rateNum > 1000) return "WiFi 6"
            if (rateNum > 400) return "WiFi 5"
            return "WiFi 4"
        }
        // 2.4 GHz band
        if (rateNum > 400) return "WiFi 6"
        if (rateNum > 54) return "WiFi 4"
        return ""  // Could be b/g
    }

    // Get signal icon based on strength
    function getSignalIcon(signal) {
        const signalNum = typeof signal === "string" ? parseInt(signal) : (signal || 0)
        if (signalNum >= 70) return MaterialSymbols.wifi
        if (signalNum >= 40) return MaterialSymbols.wifi2Bar
        return MaterialSymbols.wifi1Bar
    }

    // Format security string for display
    // security is from nmcli (e.g., "WPA2", "WPA3", "")
    function formatSecurity(security) {
        if (!security || security === "--" || security === "") return "Open"
        // Clean up common formats
        return security
            .replace("WPA2", "WPA2")
            .replace("WPA3", "WPA3")
            .replace("WPA1", "WPA")
            .replace("802.1X", "Enterprise")
    }

    Row {
        anchors.left: parent.left
        anchors.leftMargin: 8
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10

        // Signal strength icon
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.getSignalIcon(root.network?.signal)
            color: root.isConnected ? Theme.colors.accent : Theme.colors.textSecondary
            font.pixelSize: 20
            font.family: Theme.iconFont
        }

        // Network info
        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2
            width: parent.width - 80  // Leave room for icon and checkmark

            // SSID
            Text {
                width: parent.width
                text: root.network?.ssid || "(Hidden Network)"
                color: root.isConnected ? Theme.colors.text : Theme.colors.textSecondary
                font.pixelSize: 13
                font.weight: root.isConnected ? 600 : 400
                elide: Text.ElideRight
            }

            // Details row: Security • Band • Generation
            Row {
                spacing: 6

                Text {
                    text: root.formatSecurity(root.network?.security)
                    color: Theme.colors.textMuted
                    font.pixelSize: 11
                }

                Text {
                    visible: !!root.getBand(root.network?.freq)
                    text: "•"
                    color: Theme.colors.textFaint
                    font.pixelSize: 11
                }

                Text {
                    visible: !!root.getBand(root.network?.freq)
                    text: root.getBand(root.network?.freq)
                    color: Theme.colors.textMuted
                    font.pixelSize: 11
                }

                Text {
                    visible: !!root.getWifiGeneration(root.network?.freq, root.network?.rate)
                    text: "•"
                    color: Theme.colors.textFaint
                    font.pixelSize: 11
                }

                Text {
                    visible: !!root.getWifiGeneration(root.network?.freq, root.network?.rate)
                    text: root.getWifiGeneration(root.network?.freq, root.network?.rate)
                    color: Theme.colors.textMuted
                    font.pixelSize: 11
                }
            }
        }

        // Connected checkmark or chevron
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.isConnected ? MaterialSymbols.check : MaterialSymbols.chevronRight
            color: root.isConnected ? Theme.colors.accent : Theme.colors.textFaint
            font.pixelSize: root.isConnected ? 16 : 18
            font.family: Theme.iconFont
        }
    }

    HoverHandler {
        id: hoverHandler
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        onTapped: root.clicked()
    }
}
