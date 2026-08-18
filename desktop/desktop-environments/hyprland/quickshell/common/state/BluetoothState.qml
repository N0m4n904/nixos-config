pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Bluetooth

Singleton {
    id: root

    // Whether any Bluetooth adapter exists
    readonly property bool hasAdapter: Bluetooth.adapters.values.length > 0

    // The default adapter (first available)
    readonly property var defaultAdapter: Bluetooth.defaultAdapter

    // Whether Bluetooth is enabled (any adapter powered on)
    readonly property bool isEnabled: defaultAdapter?.enabled ?? false

    // Whether any device is currently connected
    readonly property bool hasConnectedDevice: {
        for (let i = 0; i < Bluetooth.adapters.values.length; i++) {
            const adapter = Bluetooth.adapters.values[i]
            if (!adapter.enabled) continue
            for (let j = 0; j < adapter.devices.values.length; j++) {
                if (adapter.devices.values[j].connected) return true
            }
        }
        return false
    }

    // Name of the first connected device (for display)
    readonly property string connectedDeviceName: {
        for (let i = 0; i < Bluetooth.adapters.values.length; i++) {
            const adapter = Bluetooth.adapters.values[i]
            if (!adapter.enabled) continue
            for (let j = 0; j < adapter.devices.values.length; j++) {
                const device = adapter.devices.values[j]
                if (device.connected) {
                    return device.name || device.deviceName || ""
                }
            }
        }
        return ""
    }

    // All adapters (for advanced use)
    readonly property var adapters: Bluetooth.adapters

    // Toggle Bluetooth on/off
    function toggle() {
        if (defaultAdapter) {
            defaultAdapter.enabled = !defaultAdapter.enabled
        }
    }

    // Enable Bluetooth
    function enable() {
        if (defaultAdapter) {
            defaultAdapter.enabled = true
        }
    }

    // Disable Bluetooth
    function disable() {
        if (defaultAdapter) {
            defaultAdapter.enabled = false
        }
    }
}
