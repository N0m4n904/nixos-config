import QtQuick
import QtQuick.Controls
import Quickshell.Bluetooth
import qs.common.lib
import qs.common.state
import "bluetooth"

Item {
    id: root
    implicitHeight: stackView.currentItem?.implicitHeight ?? 200

    property bool readOnly: false

    property var selectedDevice: null
    property bool onConnectPage: false

    property alias discovering: state.discovering
    property alias connecting: state.connecting
    property alias pairing: state.pairing
    property alias connectionError: state.connectionError
    property alias pairingError: state.pairingError
    property alias selectedAdapter: data.selectedAdapter

    QtObject {
        id: state
        property bool discovering: false
        property bool connecting: false
        property bool pairing: false
        property string connectionError: ""
        property string pairingError: ""
    }

    QtObject {
        id: data
        property var selectedAdapter: null
    }

    function reset() {
        stackView.pop(null)
        state.discovering = false
        state.connecting = false
        state.pairing = false
        state.connectionError = ""
        state.pairingError = ""
        root.selectedDevice = null
        root.onConnectPage = false
    }

    readonly property var sortedAdapters: {
        const adapters = []
        for (let i = 0; i < BluetoothState.adapters.values.length; i++) {
            adapters.push(BluetoothState.adapters.values[i])
        }
        return adapters.sort((a, b) => {
            if (a.enabled !== b.enabled) return b.enabled - a.enabled
            return (a.adapterId || "").localeCompare(b.adapterId || "")
        })
    }

    Component.onCompleted: {
        if (sortedAdapters.length === 1) {
            data.selectedAdapter = sortedAdapters[0]
            stackView.replace(null, deviceListPage)
        }
    }

    function startDiscovery() {
        if (data.selectedAdapter) {
            data.selectedAdapter.discovering = true
        }
    }

    Connections {
        target: data.selectedAdapter
        function onDiscoveringChanged() {
            if (data.selectedAdapter) {
                state.discovering = data.selectedAdapter.discovering
            }
        }
    }

    StackView {
        id: stackView
        anchors.fill: parent
        clip: true
        initialItem: adapterPage

        pushEnter: Transition {
            ParallelAnimation {
                PropertyAnimation { property: "x"; from: stackView.width; to: 0; duration: Theme.duration.relaxed; easing.type: Easing.OutCubic }
                PropertyAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.duration.fast }
            }
        }
        pushExit: Transition {
            ParallelAnimation {
                PropertyAnimation { property: "x"; from: 0; to: -stackView.width * 0.3; duration: Theme.duration.relaxed; easing.type: Easing.OutCubic }
                PropertyAnimation { property: "opacity"; from: 1; to: 0; duration: Theme.duration.fast }
            }
        }
        popEnter: Transition {
            ParallelAnimation {
                PropertyAnimation { property: "x"; from: -stackView.width * 0.3; to: 0; duration: Theme.duration.relaxed; easing.type: Easing.OutCubic }
                PropertyAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.duration.fast }
            }
        }
        popExit: Transition {
            ParallelAnimation {
                PropertyAnimation { property: "x"; from: 0; to: stackView.width; duration: Theme.duration.relaxed; easing.type: Easing.OutCubic }
                PropertyAnimation { property: "opacity"; from: 1; to: 0; duration: Theme.duration.fast }
            }
        }
    }

    Component {
        id: adapterPage
        AdapterPage {
            adapters: root.sortedAdapters
            onAdapterClicked: adapter => {
                data.selectedAdapter = adapter
                stackView.push(deviceListPage)
            }
        }
    }

    Component {
        id: deviceListPage
        DeviceListPage {
            adapter: root.selectedAdapter
            discovering: root.discovering
            connecting: root.connecting
            multiAdapter: root.sortedAdapters.length > 1
            onBack: stackView.pop()
            onScanRequested: root.startDiscovery()
            onDeviceSelected: device => {
                root.selectedDevice = device
                if (device.state === BluetoothDeviceState.Connected) {
                    stackView.push(detailsPage)
                } else if (device.paired) {
                    state.connectionError = ""
                    device.connected = true
                } else {
                    root.onConnectPage = true
                    stackView.push(connectPage)
                }
            }
            onViewDetails: device => {
                root.selectedDevice = device
                stackView.push(detailsPage)
            }
        }
    }

    Component {
        id: connectPage
        ConnectPage {
            device: root.selectedDevice
            pairing: root.pairing
            connecting: root.connecting
            pairingError: root.pairingError
            connectionError: root.connectionError
            onBack: {
                if (state.pairing && root.selectedDevice) {
                    root.selectedDevice.cancelPair()
                }
                state.pairing = false
                state.connecting = false
                state.pairingError = ""
                state.connectionError = ""
                root.onConnectPage = false
                stackView.pop()
            }
            onPairRequested: {
                state.pairing = true
                state.pairingError = ""
                root.selectedDevice.pair()
            }
            onCancelPairRequested: {
                state.pairing = false
                root.selectedDevice.cancelPair()
            }
        }
    }

    Component {
        id: detailsPage
        DetailsPage {
            device: root.selectedDevice
            onBack: stackView.pop()
            onDisconnectRequested: {
                root.selectedDevice.connected = false
                stackView.pop()
            }
            onForgetRequested: {
                root.selectedDevice.forget()
                stackView.pop()
            }
        }
    }

    Connections {
        target: root.selectedDevice
        enabled: !!root.selectedDevice

        function onPairingChanged() {
            if (!root.selectedDevice) return
            if (!root.selectedDevice.pairing && state.pairing && !root.selectedDevice.paired) {
                state.pairing = false
                state.pairingError = "Pairing failed. Ensure device is in pairing mode."
            }
        }

        function onPairedChanged() {
            if (!root.selectedDevice) return
            if (root.selectedDevice.paired && state.pairing) {
                state.pairing = false
                state.connectionError = ""
                root.selectedDevice.connected = true
            }
        }

        function onStateChanged() {
            if (!root.selectedDevice) return
            const deviceState = root.selectedDevice.state

            if (deviceState === BluetoothDeviceState.Connected) {
                state.connectionError = ""
                if (root.onConnectPage) {
                    root.onConnectPage = false
                    stackView.pop()
                }
            } else if (deviceState === BluetoothDeviceState.Disconnected && state.connecting) {
                state.connecting = false
                state.connectionError = "Connection failed. Try again."
            }

            state.connecting = (deviceState === BluetoothDeviceState.Connecting)
        }
    }
}
