import QtQuick
import Quickshell.Bluetooth
import qs.common.lib

Rectangle {
    id: root
    height: 52
    color: hoverHandler.hovered ? Theme.colors.hover : "transparent"
    radius: 6

    required property var device

    readonly property bool isConnected: root.device?.state === BluetoothDeviceState.Connected
    readonly property bool isConnecting: root.device?.state === BluetoothDeviceState.Connecting
    readonly property bool isDisconnecting: root.device?.state === BluetoothDeviceState.Disconnecting
    readonly property bool isBusy: root.isConnecting || root.isDisconnecting

    signal clicked()

    Behavior on color { ColorAnimation { duration: Theme.duration.fast } }

    Row {
        anchors.left: parent.left
        anchors.leftMargin: 8
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Formatting.formatBluetoothDeviceIcon(root.device?.icon)
            color: root.isConnected ? Theme.colors.accent : Theme.colors.textSecondary
            font.pixelSize: 20
            font.family: Theme.iconFont
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2
            width: parent.width - 80

            Text {
                width: parent.width
                text: root.device?.name || root.device?.deviceName || "Unknown Device"
                color: root.isConnected ? Theme.colors.text : Theme.colors.textSecondary
                font.pixelSize: 13
                font.weight: root.isConnected ? 600 : 400
                elide: Text.ElideRight
            }

            Row {
                spacing: 6

                Text {
                    text: {
                        if (root.isConnected) return "Connected"
                        if (root.isConnecting) return "Connecting…"
                        if (root.isDisconnecting) return "Disconnecting…"
                        if (root.device?.pairing) return "Pairing…"
                        if (root.device?.paired) return "Paired"
                        return "Available"
                    }
                    color: Theme.colors.textMuted
                    font.pixelSize: 11

                    SequentialAnimation on opacity {
                        running: root.isBusy || (root.device?.pairing ?? false)
                        loops: Animation.Infinite
                        NumberAnimation { to: 0.3; duration: 400 }
                        NumberAnimation { to: 1; duration: 400 }
                    }
                }

                Text {
                    visible: root.device?.batteryAvailable ?? false
                    text: "•"
                    color: Theme.colors.textFaint
                    font.pixelSize: 11
                }

                Text {
                    visible: root.device?.batteryAvailable ?? false
                    text: root.device?.batteryAvailable ? Math.round(root.device.battery * 100) + "%" : ""
                    color: {
                        if (!root.device?.batteryAvailable) return Theme.colors.textMuted
                        const pct = root.device.battery * 100
                        if (pct <= 10) return Theme.colors.danger
                        if (pct <= 20) return Theme.colors.warning
                        return Theme.colors.textMuted
                    }
                    font.pixelSize: 11
                }
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: {
                if (root.isConnected) return MaterialSymbols.check
                if (root.device?.paired) return MaterialSymbols.link
                return MaterialSymbols.chevronRight
            }
            color: {
                if (root.isConnected) return Theme.colors.accent
                if (root.device?.paired) return Theme.colors.textMuted
                return Theme.colors.textFaint
            }
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
