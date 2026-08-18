import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Io
import qs.common.lib
import qs.common.state
import "network"

Item {
    id: root
    implicitHeight: stackView.currentItem?.implicitHeight ?? 200

    property bool readOnly: false
    property bool reduced: false

    // Aliases for proper binding notifications in Components
    property alias deviceDetails: state.deviceDetails
    property alias deviceSpeedMbps: state.deviceSpeedMbps
    property alias scanning: state.scanning
    property alias wifiNetworks: state.wifiNetworks
    property alias connecting: state.connecting
    property alias connectionError: state.connectionError
    property alias selectedNetwork: state.selectedNetwork
    readonly property string primaryDevice: NetworkState.primaryDevice
    property alias deviceRoutes: state.deviceRoutes

    // Ephemeral UI state - cleared when panel closes
    QtObject {
        id: state
        property bool scanning: false
        property var wifiNetworks: []
        property var deviceDetails: null
        property int deviceSpeedMbps: 0
        // WiFi connection state
        property bool connecting: false
        property string connectionError: ""
        property var selectedNetwork: null  // Network being connected to or viewed
        property var deviceRoutes: []  // Routes for the selected device
    }

    function refreshDevices() {
        NetworkState.refresh()
    }

    function reset() {
        stackView.pop(null)
        state.scanning = false
        state.wifiNetworks = []
        state.deviceDetails = null
        state.deviceSpeedMbps = 0
        state.connecting = false
        state.connectionError = ""
        state.selectedNetwork = null
        state.deviceRoutes = []
        selectedDevice = null
    }

    function connectToWifi(ssid, password) {
        state.connecting = true
        state.connectionError = ""
        if (password) {
            nmcliWifiConnect.command = ["nmcli", "device", "wifi", "connect", ssid, "password", password]
        } else {
            // For open networks or when NetworkManager has saved credentials
            nmcliWifiConnect.command = ["nmcli", "device", "wifi", "connect", ssid]
        }
        nmcliWifiConnect.running = true
    }

    function selectNetwork(network) {
        state.selectedNetwork = network
        // Load details for the selected device's interface
        if (selectedDevice?.device) {
            loadDeviceDetails(selectedDevice.device)
        }
    }

    function disconnectWifi() {
        if (selectedDevice?.device) {
            nmcliDisconnect.command = ["nmcli", "device", "disconnect", selectedDevice.device]
            nmcliDisconnect.running = true
        }
    }

    function loadDeviceDetails(deviceName) {
        state.deviceDetails = null
        state.deviceSpeedMbps = 0
        nmcliDeviceDetails.command = ["jc", "nmcli", "device", "show", deviceName]
        nmcliDeviceDetails.running = true
        deviceSpeedFile.path = "/sys/class/net/" + deviceName + "/speed"
        deviceSpeedFile.reload()
    }

    function loadDeviceRoutes(deviceName) {
        state.deviceRoutes = []
        ipRouteDevice.command = ["jc", "ip", "route", "show", "dev", deviceName]
        ipRouteDevice.running = true
    }

    // Fetch routes for a specific device
    Process {
        id: ipRouteDevice
        command: []

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    state.deviceRoutes = JSON.parse(text)
                } catch (e) {
                    state.deviceRoutes = []
                }
            }
        }
    }

    Process {
        id: nmcliWifi
        command: []
        environment: Object.assign({}, Qt.application.environment, { LC_ALL: "C" })

        stdout: StdioCollector {
            onStreamFinished: {
                state.scanning = false
                try {
                    state.wifiNetworks = root.parseWifiList(text)
                } catch (e) {
                    console.log("Failed to parse WiFi list:", e)
                    state.wifiNetworks = []
                }
            }
        }
    }

    // WiFi connection process
    Process {
        id: nmcliWifiConnect
        command: []

        stdout: StdioCollector {
            onStreamFinished: {
                state.connecting = false
                // Connection initiated - NetworkManager will handle password prompts
            }
        }

        onExited: (code, status) => {
            state.connecting = false
            if (code !== 0) {
                state.connectionError = "Connection failed"
            } else {
                state.connectionError = ""
                // Refresh network list after successful connection
                nmcliWifi.running = true
                nmcliDevices.running = true
                // Go back to WiFi list on success
                stackView.pop()
            }
        }
    }

    // WiFi disconnect process
    Process {
        id: nmcliDisconnect
        command: []

        onExited: (code, status) => {
            // Refresh network list after disconnect
            nmcliWifi.running = true
            nmcliDevices.running = true
            // Go back to WiFi list
            stackView.pop()
        }
    }

    Process {
        id: nmcliDeviceDetails
        command: []

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const arr = JSON.parse(text)
                    state.deviceDetails = arr.length > 0 ? arr[0] : null
                } catch (e) {
                    state.deviceDetails = null
                }
            }
        }
    }

    FileView {
        id: deviceSpeedFile
        onLoaded: {
            const speed = parseInt(text().trim(), 10)
            state.deviceSpeedMbps = isNaN(speed) ? 0 : speed
        }
        onLoadFailed: state.deviceSpeedMbps = 0
    }

    // Parse nmcli terse output to JSON
    // Format: SSID:BSSID:SIGNAL:SECURITY:FREQ:RATE:CHAN:IN-USE:MODE
    function parseWifiList(text) {
        const lines = text.trim().split("\n").filter(l => l.length > 0)
        return lines.map(line => {
            // nmcli escapes colons in BSSID as \:, temporarily replace them
            const escaped = line.replace(/\\:/g, "\x00")
            const parts = escaped.split(":")
            return {
                ssid: parts[0] || "",
                bssid: (parts[1] || "").replace(/\x00/g, ":"),
                signal: parts[2] || "0",
                security: parts[3] || "",
                freq: (parts[4] || "").replace(" MHz", ""),
                rate: (parts[5] || "").replace(" Mbit/s", ""),
                chan: parts[6] || "",
                in_use: parts[7] || "",
                mode: parts[8] || ""
            }
        })
    }

    function scanWifi(deviceName) {
        state.scanning = true
        // Use nmcli terse mode for easy parsing
        if (deviceName) {
            nmcliWifi.command = ["nmcli", "-t", "-f", "SSID,BSSID,SIGNAL,SECURITY,FREQ,RATE,CHAN,IN-USE,MODE", "device", "wifi", "list", "ifname", deviceName]
        } else {
            nmcliWifi.command = ["nmcli", "-t", "-f", "SSID,BSSID,SIGNAL,SECURITY,FREQ,RATE,CHAN,IN-USE,MODE", "device", "wifi", "list"]
        }
        nmcliWifi.running = true
    }

    // Filtered devices (arrays for multiple adapters)
    readonly property var wifiDevices: NetworkState.devices.filter(d => d.type === "wifi" && d.state !== "unmanaged")
    readonly property var ethernetDevices: NetworkState.devices.filter(d =>
        d.type === "ethernet" &&
        d.state !== "unmanaged" &&
        !d.device.startsWith("veth") &&
        !d.device.startsWith("br-") &&
        !d.device.startsWith("docker")
    )

    // Combined and sorted: connected first, then by type (wifi, ethernet)
    readonly property var allDevices: {
        const all = [...wifiDevices, ...ethernetDevices]
        return all.sort((a, b) => {
            // Connected devices first
            const aConnected = a.state === "connected" ? 0 : 1
            const bConnected = b.state === "connected" ? 0 : 1
            if (aConnected !== bConnected) return aConnected - bConnected
            // Then by type (wifi before ethernet)
            const typeOrder = { wifi: 0, ethernet: 1 }
            return (typeOrder[a.type] ?? 2) - (typeOrder[b.type] ?? 2)
        })
    }

    // Currently selected device for detail pages
    property var selectedDevice: null

    StackView {
        id: stackView
        anchors.fill: parent
        clip: true
        initialItem: mainPage

        pushEnter: Transition {
            ParallelAnimation {
                PropertyAnimation {
                    property: "x"
                    from: stackView.width
                    to: 0
                    duration: Theme.duration.relaxed
                    easing.type: Easing.OutCubic
                }
                PropertyAnimation {
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: Theme.duration.fast
                }
            }
        }
        pushExit: Transition {
            ParallelAnimation {
                PropertyAnimation {
                    property: "x"
                    from: 0
                    to: -stackView.width * 0.3
                    duration: Theme.duration.relaxed
                    easing.type: Easing.OutCubic
                }
                PropertyAnimation {
                    property: "opacity"
                    from: 1
                    to: 0
                    duration: Theme.duration.fast
                }
            }
        }
        popEnter: Transition {
            ParallelAnimation {
                PropertyAnimation {
                    property: "x"
                    from: -stackView.width * 0.3
                    to: 0
                    duration: Theme.duration.relaxed
                    easing.type: Easing.OutCubic
                }
                PropertyAnimation {
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: Theme.duration.fast
                }
            }
        }
        popExit: Transition {
            ParallelAnimation {
                PropertyAnimation {
                    property: "x"
                    from: 0
                    to: stackView.width
                    duration: Theme.duration.relaxed
                    easing.type: Easing.OutCubic
                }
                PropertyAnimation {
                    property: "opacity"
                    from: 1
                    to: 0
                    duration: Theme.duration.fast
                }
            }
        }
    }

    // Main page - network device selection
    Component {
        id: mainPage

        MainPage {
            devices: root.allDevices
            primaryDevice: root.primaryDevice
            onDeviceClicked: device => {
                root.selectedDevice = device
                if (device.type === "wifi") {
                    if (root.readOnly) {
                        // In read-only mode, show simplified WiFi page (no scanning)
                        root.selectedDevice = device
                        stackView.push(wifiReadOnlyPage)
                    } else {
                        root.scanWifi(device.device)
                        stackView.push(wifiPage)
                    }
                } else if (device.type === "ethernet") {
                    root.loadDeviceDetails(device.device)
                    stackView.push(ethernetPage)
                }
            }
        }
    }

    // WiFi read-only page (for lockscreen)
    Component {
        id: wifiReadOnlyPage

        WifiReadOnlyPage {
            wifiDevice: root.selectedDevice
            connectedNetwork: root.wifiNetworks.find(n => n.in_use === "*")
            onBack: stackView.pop()
        }
    }

    // WiFi page
    Component {
        id: wifiPage

        WifiPage {
            wifiDevice: root.selectedDevice
            wifiNetworks: root.wifiNetworks
            scanning: root.scanning
            connecting: root.connecting
            connectionError: root.connectionError
            onBack: stackView.pop()
            onScanRequested: root.scanWifi(root.selectedDevice?.device)
            onNetworkSelected: network => {
                root.selectNetwork(network)
                // If already connected to this network, show details
                if (network.in_use === "*") {
                    stackView.push(wifiDetailsPage)
                } else {
                    // Show connect page
                    stackView.push(wifiConnectPage)
                }
            }
            onViewDetails: {
                // Select the connected network before viewing details
                const connected = root.wifiNetworks.find(n => n.in_use === "*")
                if (connected) {
                    root.selectNetwork(connected)
                }
                stackView.push(wifiDetailsPage)
            }
            onConnectRequested: (ssid, password) => root.connectToWifi(ssid, password)
        }
    }

    // WiFi details page (for connected network)
    Component {
        id: wifiDetailsPage

        WifiDetailsPage {
            wifiDevice: root.selectedDevice
            deviceDetails: root.deviceDetails
            deviceSpeedMbps: root.deviceSpeedMbps
            connectedNetwork: root.selectedNetwork
            reduced: root.reduced
            onBack: stackView.pop()
            onDisconnect: root.disconnectWifi()
            onViewRoutes: {
                root.loadDeviceRoutes(root.selectedDevice?.device)
                stackView.push(routesPage)
            }
        }
    }

    // WiFi connect page (for connecting to new network)
    Component {
        id: wifiConnectPage

        WifiConnectPage {
            network: root.selectedNetwork
            connecting: root.connecting
            connectionError: root.connectionError
            onBack: stackView.pop()
            onConnect: password => {
                root.connectToWifi(root.selectedNetwork?.ssid ?? "", password)
            }
        }
    }

    // Ethernet page
    Component {
        id: ethernetPage

        EthernetPage {
            ethernetDevice: root.selectedDevice
            deviceDetails: root.deviceDetails
            deviceSpeedMbps: root.deviceSpeedMbps
            reduced: root.reduced
            onBack: stackView.pop()
            onViewRoutes: {
                root.loadDeviceRoutes(root.selectedDevice?.device)
                stackView.push(routesPage)
            }
        }
    }

    // Routes page
    Component {
        id: routesPage

        RoutesPage {
            device: root.selectedDevice
            routes: root.deviceRoutes
            onBack: stackView.pop()
        }
    }
}
