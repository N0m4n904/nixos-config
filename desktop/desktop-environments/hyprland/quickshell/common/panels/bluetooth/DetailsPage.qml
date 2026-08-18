import QtQuick
import Quickshell.Bluetooth
import qs.common.lib
import ".."

Column {
    id: root
    spacing: 0

    property var device: null

    readonly property bool isConnected: root.device?.state === BluetoothDeviceState.Connected

    signal back()
    signal disconnectRequested()
    signal forgetRequested()

    PageHeader {
        width: parent.width
        title: root.device?.name || root.device?.deviceName || "Device"
        onBack: root.back()
    }

    Column {
        width: parent.width
        topPadding: 8
        spacing: 12

        DetailRow {
            width: parent.width
            label: "Status"
            value: {
                if (!root.device) return "Unknown"
                switch (root.device.state) {
                    case BluetoothDeviceState.Connected: return "Connected"
                    case BluetoothDeviceState.Connecting: return "Connecting…"
                    case BluetoothDeviceState.Disconnecting: return "Disconnecting…"
                    default: return "Disconnected"
                }
            }
            valueColor: root.isConnected ? Theme.colors.success : Theme.colors.textMuted
        }

        DetailRow {
            width: parent.width
            label: "Name"
            value: root.device?.name || root.device?.deviceName || ""
        }

        DetailRow {
            width: parent.width
            label: "Device Name"
            value: root.device?.deviceName || ""
            visible: !!root.device?.deviceName && root.device?.deviceName !== root.device?.name
        }

        DetailRow {
            width: parent.width
            label: "Address"
            value: root.device?.address ?? ""
            visible: !!root.device?.address
        }

        DetailRow {
            width: parent.width
            label: "Type"
            value: root.device?.icon ?? ""
            visible: !!root.device?.icon
        }

        Rectangle {
            width: parent.width
            height: 1
            color: Theme.colors.separatorSubtle
        }

        DetailRow {
            width: parent.width
            label: "Paired"
            value: root.device?.paired ? "Yes" : "No"
        }

        DetailRow {
            width: parent.width
            label: "Bonded"
            value: root.device?.bonded ? "Yes" : "No"
            visible: root.device?.bonded ?? false
        }

        DetailRow {
            width: parent.width
            label: "Battery"
            value: Math.round((root.device?.battery ?? 0) * 100) + "%"
            valueColor: {
                const pct = (root.device?.battery ?? 0) * 100
                if (pct <= 10) return Theme.colors.danger
                if (pct <= 20) return Theme.colors.warning
                return Theme.colors.text
            }
            visible: root.device?.batteryAvailable ?? false
        }

        Rectangle {
            width: parent.width
            height: 1
            color: Theme.colors.separatorSubtle
        }

        SectionHeader { text: "Settings" }

        Item {
            width: parent.width
            height: 36

            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: "Trusted"
                color: Theme.colors.text
                font.pixelSize: 13
            }

            ToggleSwitch {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                checked: root.device?.trusted ?? false
                onToggled: {
                    if (root.device) root.device.trusted = !root.device.trusted
                }
            }
        }

        Item {
            width: parent.width
            height: 36

            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: "Wake Allowed"
                color: Theme.colors.text
                font.pixelSize: 13
            }

            ToggleSwitch {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                checked: root.device?.wakeAllowed ?? false
                onToggled: {
                    if (root.device) root.device.wakeAllowed = !root.device.wakeAllowed
                }
            }
        }

        Item {
            width: parent.width
            height: 36

            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: "Blocked"
                color: Theme.colors.text
                font.pixelSize: 13
            }

            ToggleSwitch {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                checked: root.device?.blocked ?? false
                accentColor: Theme.colors.danger
                onToggled: {
                    if (root.device) root.device.blocked = !root.device.blocked
                }
            }
        }

        Rectangle {
            width: parent.width
            height: 1
            color: Theme.colors.separatorSubtle
        }

        Item {
            width: parent.width
            height: 48
            visible: root.isConnected

            ActionButton {
                anchors.centerIn: parent
                width: parent.width - 16
                height: 36
                text: "Disconnect"
                variant: "danger"
                onClicked: root.disconnectRequested()
            }
        }

        Item {
            width: parent.width
            height: 48
            visible: root.device?.paired ?? false

            ActionButton {
                anchors.centerIn: parent
                width: parent.width - 16
                height: 36
                text: "Forget Device"
                variant: "outline"
                onClicked: root.forgetRequested()
            }
        }
    }
}
