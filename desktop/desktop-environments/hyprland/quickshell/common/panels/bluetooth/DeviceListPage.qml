import QtQuick
import Quickshell.Bluetooth
import qs.common.lib
import qs.common.state
import ".."

Column {
    id: root
    spacing: 0

    property var adapter: null
    property bool discovering: false
    property bool connecting: false
    property bool multiAdapter: false

    signal back()
    signal scanRequested()
    signal deviceSelected(var device)
    signal viewDetails(var device)

    readonly property var connectedDevices: sortedDevices.filter(d => d.state === BluetoothDeviceState.Connected)

    readonly property var sortedDevices: {
        if (!adapter?.devices) return []
        const devices = []
        for (let i = 0; i < adapter.devices.values.length; i++) {
            devices.push(adapter.devices.values[i])
        }

        const isMacAddress = (str) => /^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$/.test(str)

        return devices.sort((a, b) => {
            const aConnected = a.state === BluetoothDeviceState.Connected
            const bConnected = b.state === BluetoothDeviceState.Connected

            // 1. Connected devices first
            if (aConnected !== bConnected) return bConnected - aConnected
            if (aConnected && bConnected) {
                const nameA = a.name || a.deviceName || ""
                const nameB = b.name || b.deviceName || ""
                return nameA.localeCompare(nameB)
            }

            // 2. Paired devices next
            if (a.paired !== b.paired) return b.paired - a.paired
            if (a.paired && b.paired) {
                const nameA = a.name || a.deviceName || ""
                const nameB = b.name || b.deviceName || ""
                return nameA.localeCompare(nameB)
            }

            // 3 & 4. Available: named devices before unnamed (MAC-only)
            // RSSI not available in API, using alphabetical order
            const aDeviceName = a.deviceName || ""
            const bDeviceName = b.deviceName || ""
            const aIsUnnamed = !aDeviceName || isMacAddress(aDeviceName)
            const bIsUnnamed = !bDeviceName || isMacAddress(bDeviceName)

            if (aIsUnnamed !== bIsUnnamed) return aIsUnnamed - bIsUnnamed

            const nameA = a.name || a.deviceName || ""
            const nameB = b.name || b.deviceName || ""
            return nameA.localeCompare(nameB)
        })
    }

    readonly property int firstPairedIndex: sortedDevices.findIndex(d => d.paired && d.state !== BluetoothDeviceState.Connected)
    readonly property int firstAvailableIndex: sortedDevices.findIndex(d => !d.paired)

    PageHeader {
        width: parent.width
        title: root.adapter?.name || "Bluetooth"
        visible: root.multiAdapter
        onBack: root.back()
    }

    Column {
        visible: !root.multiAdapter
        leftPadding: 4
        bottomPadding: 12
        spacing: 2

        Text {
            text: "Bluetooth"
            color: Theme.colors.text
            font.pixelSize: 15
            font.weight: 600
        }

        Text {
            text: root.adapter?.name || ""
            color: Theme.colors.textMuted
            font.pixelSize: 11
            visible: !!root.adapter?.name
        }
    }

    Item {
        width: parent.width
        height: 36

        Row {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.adapter?.enabled ? MaterialSymbols.bluetooth : MaterialSymbols.bluetoothDisabled
                color: root.adapter?.enabled ? Theme.colors.accent : Theme.colors.textFaint
                font.pixelSize: 18
                font.family: Theme.iconFont
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.adapter?.enabled ? "On" : "Off"
                color: Theme.colors.text
                font.pixelSize: 13
                font.weight: 500
            }
        }

        ToggleSwitch {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            checked: root.adapter?.enabled ?? false
            onToggled: {
                if (root.adapter) root.adapter.enabled = !root.adapter.enabled
            }
        }
    }

    // Discoverable toggle
    Item {
        width: parent.width
        height: 32
        visible: root.adapter?.enabled ?? false

        Row {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: MaterialSymbols.bluetoothSearching
                color: root.adapter?.discoverable ? Theme.colors.accent : Theme.colors.textFaint
                font.pixelSize: 16
                font.family: Theme.iconFont
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "Discoverable"
                color: Theme.colors.textSecondary
                font.pixelSize: 12
            }
        }

        ToggleSwitch {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            checked: root.adapter?.discoverable ?? false
            onToggled: {
                if (root.adapter) root.adapter.discoverable = !root.adapter.discoverable
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
        height: connectionStatus.height + 16
        visible: root.connectedDevices.length > 0

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
                    text: {
                        const names = root.connectedDevices.map(d => d.name || d.deviceName || "Device")
                        if (names.length === 1) return "Connected to " + names[0]
                        return names.length + " devices connected"
                    }
                    color: Theme.colors.text
                    font.pixelSize: 13
                    font.weight: 500
                }
            }

            Rectangle {
                width: viewDetailsRow.width + 16
                height: 24
                radius: 12
                color: viewDetailsHover.hovered ? Theme.colors.hover : "transparent"
                visible: root.connectedDevices.length === 1

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
                    onTapped: root.viewDetails(root.connectedDevices[0])
                }
            }
        }
    }

    Rectangle {
        width: parent.width
        height: 1
        color: Theme.colors.separatorSubtle
        visible: root.connectedDevices.length > 0
    }

    Item {
        width: parent.width
        height: 32
        visible: root.adapter?.enabled

        FieldLabel {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: "Devices"
        }

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
                opacity: root.discovering ? 0.5 : (scanHover.hovered ? 1 : 0.8)

                Behavior on opacity { NumberAnimation { duration: Theme.duration.fast } }

                RotationAnimation on rotation {
                    running: root.discovering
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
                enabled: !root.discovering
                onTapped: root.scanRequested()
            }
        }
    }

    Column {
        width: parent.width
        spacing: 0
        visible: root.adapter?.enabled

        Repeater {
            model: root.sortedDevices

            Column {
                width: parent.width

                Item {
                    width: parent.width
                    height: 24
                    visible: {
                        const isConnected = modelData.state === BluetoothDeviceState.Connected
                        if (index === 0 && isConnected) return true
                        if (index === root.firstPairedIndex && root.firstPairedIndex > 0) return true
                        if (index === root.firstAvailableIndex && root.firstAvailableIndex > 0) return true
                        return false
                    }

                    Text {
                        anchors.left: parent.left
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 2
                        text: {
                            if (modelData.state === BluetoothDeviceState.Connected) return "Connected"
                            if (modelData.paired) return "Paired"
                            return "Available"
                        }
                        color: Theme.colors.textFaint
                        font.pixelSize: 10
                        font.weight: 500
                    }
                }

                DeviceRow {
                    width: parent.width
                    device: modelData
                    onClicked: root.deviceSelected(modelData)
                }
            }
        }

        Item {
            width: parent.width
            height: 60
            visible: root.sortedDevices.length === 0 && !root.discovering

            Column {
                anchors.centerIn: parent
                spacing: 4

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: MaterialSymbols.bluetoothSearching
                    color: Theme.colors.textMuted
                    font.pixelSize: 24
                    font.family: Theme.iconFont
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "No devices found"
                    color: Theme.colors.textMuted
                    font.pixelSize: 12
                }
            }
        }

        Item {
            width: parent.width
            height: 60
            visible: root.discovering && root.sortedDevices.length === 0

            Column {
                anchors.centerIn: parent
                spacing: 4

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: MaterialSymbols.bluetoothSearching
                    color: Theme.colors.textMuted
                    font.pixelSize: 24
                    font.family: Theme.iconFont

                    SequentialAnimation on opacity {
                        running: root.discovering
                        loops: Animation.Infinite
                        NumberAnimation { to: 0.3; duration: 500 }
                        NumberAnimation { to: 1; duration: 500 }
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Scanning…"
                    color: Theme.colors.textMuted
                    font.pixelSize: 12
                }
            }
        }
    }

    Item {
        width: parent.width
        height: 80
        visible: !root.adapter?.enabled

        Column {
            anchors.centerIn: parent
            spacing: 4

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: MaterialSymbols.bluetoothDisabled
                color: Theme.colors.textMuted
                font.pixelSize: 24
                font.family: Theme.iconFont
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Bluetooth is turned off"
                color: Theme.colors.textMuted
                font.pixelSize: 12
            }
        }
    }
}
