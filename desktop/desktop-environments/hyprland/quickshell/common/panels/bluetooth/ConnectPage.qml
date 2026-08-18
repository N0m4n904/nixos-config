import QtQuick
import Quickshell.Bluetooth
import qs.common.lib
import ".."

Column {
    id: root
    spacing: 0

    property var device: null
    property bool pairing: false
    property bool connecting: false
    property string pairingError: ""
    property string connectionError: ""

    signal back()
    signal pairRequested()
    signal cancelPairRequested()

    readonly property bool isConnecting: root.device?.state === BluetoothDeviceState.Connecting
    readonly property bool isBusy: root.pairing || root.connecting || root.isConnecting
    readonly property string currentError: root.pairingError || root.connectionError

    PageHeader {
        width: parent.width
        title: root.device?.name || root.device?.deviceName || "Pair Device"
        onBack: root.back()
    }

    Column {
        width: parent.width
        topPadding: 8
        spacing: 12

        Row {
            spacing: 8

            Text {
                text: Formatting.formatBluetoothDeviceIcon(root.device?.icon)
                color: Theme.colors.accent
                font.pixelSize: 24
                font.family: Theme.iconFont
            }

            Column {
                spacing: 2

                Text {
                    text: root.device?.name || root.device?.deviceName || "Unknown Device"
                    color: Theme.colors.text
                    font.pixelSize: 15
                    font.weight: 600
                }

                Text {
                    text: root.device?.address ?? ""
                    color: Theme.colors.textMuted
                    font.pixelSize: 11
                }
            }
        }

        Rectangle {
            width: parent.width
            height: 1
            color: Theme.colors.separatorSubtle
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
            value: root.device?.icon ?? "Unknown"
            visible: !!root.device?.icon
        }

        Item {
            width: parent.width
            height: 48
            visible: root.isBusy

            Row {
                anchors.centerIn: parent
                spacing: 8

                Text {
                    text: root.pairing ? MaterialSymbols.bluetoothSearching : MaterialSymbols.bluetooth
                    color: Theme.colors.accent
                    font.pixelSize: 18
                    font.family: Theme.iconFont

                    SequentialAnimation on opacity {
                        running: root.isBusy
                        loops: Animation.Infinite
                        NumberAnimation { to: 0.3; duration: 400 }
                        NumberAnimation { to: 1; duration: 400 }
                    }
                }

                Text {
                    text: root.pairing ? "Pairing…" : "Connecting…"
                    color: Theme.colors.textMuted
                    font.pixelSize: 12
                }
            }
        }

        Text {
            width: parent.width
            visible: root.pairing
            text: "Check your device for a pairing confirmation."
            color: Theme.colors.textFaint
            font.pixelSize: 10
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
        }

        ErrorMessage {
            width: parent.width
            message: root.currentError
        }

        Item {
            width: parent.width
            height: 48

            ActionButton {
                anchors.centerIn: parent
                width: parent.width
                text: {
                    if (root.pairing) return "Cancel Pairing"
                    if (root.connecting) return "Connecting…"
                    if (root.currentError) return "Retry"
                    return "Pair"
                }
                variant: root.pairing ? "danger" : "primary"
                loading: root.connecting
                enabled: !root.connecting
                onClicked: {
                    if (root.pairing) {
                        root.cancelPairRequested()
                    } else {
                        root.pairRequested()
                    }
                }
            }
        }
    }
}
