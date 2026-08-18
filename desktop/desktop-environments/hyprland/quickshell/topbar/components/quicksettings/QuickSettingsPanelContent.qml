import QtQuick
import QtQuick.Layouts
import qs.common.lib
import qs.common.state
import qs.common.panels.quicksettings
import "tiles"

ColumnLayout {
    id: root
    spacing: 8

    // Row 1: WiFi + Bluetooth (half each)
    RowLayout {
        id: wifiBtRow
        Layout.fillWidth: true
        spacing: 8
        visible: wifiLoader.active || bluetoothLoader.active

        Loader {
            id: wifiLoader
            active: NetworkState.devices.some(d => d.type === "wifi" && d.state !== "unmanaged")
            Layout.fillWidth: true
            Layout.preferredHeight: active ? 64 : 0
            sourceComponent: WifiTile {}
        }

        Loader {
            id: bluetoothLoader
            active: BluetoothState.hasAdapter
            Layout.fillWidth: true
            Layout.preferredHeight: active ? 64 : 0
            sourceComponent: BluetoothTile {}
        }
    }

    // Row 2: Ethernet
    EthernetTile {
        Layout.fillWidth: true
        Layout.preferredHeight: 64
    }

    // Row 3: Brightness slider
    BrightnessSlider {
        Layout.fillWidth: true
        Layout.preferredHeight: 48
    }

    // Row 4: Volume slider
    VolumeSlider {
        Layout.fillWidth: true
        Layout.preferredHeight: 48
    }

    // Row 5: Power strip
    QSPowerStrip {
        Layout.fillWidth: true
        Layout.preferredHeight: 64
    }
}
