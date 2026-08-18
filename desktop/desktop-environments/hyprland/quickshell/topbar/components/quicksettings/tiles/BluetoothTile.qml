import QtQuick
import qs.common.lib
import qs.common.state
import ".."

QSTile {
    id: root

    colSpan: 4
    rowSpan: 2

    icon: {
        if (!BluetoothState.hasAdapter) return MaterialSymbols.bluetoothDisabled
        if (BluetoothState.hasConnectedDevice) return MaterialSymbols.bluetoothConnected
        if (BluetoothState.isEnabled) return MaterialSymbols.bluetooth
        return MaterialSymbols.bluetoothDisabled
    }

    label: "Bluetooth"
    subtitle: {
        if (!BluetoothState.hasAdapter) return "Unavailable"
        if (BluetoothState.connectedDeviceName) return BluetoothState.connectedDeviceName
        return BluetoothState.isEnabled ? "On" : "Off"
    }

    active: BluetoothState.isEnabled
    enabled: BluetoothState.hasAdapter

    onIconClick: BluetoothState.toggle()
    onClick: PanelManager.toggle(PanelManager.bluetooth)
}
