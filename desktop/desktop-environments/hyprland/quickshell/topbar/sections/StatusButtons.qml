import QtQuick
import QtQuick.Layouts
import qs.common.lib
import qs.common.data
import qs.common.state
import qs.common.widgets

// Openers for the ported panels. Each button reports the state of the thing it opens
// rather than only whether its panel is showing, so the bar and the panel cannot
// disagree about whether bluetooth is on.
RowLayout {
    id: root

    // The bar surface these sit on, so a panel opens against the right monitor.
    property var hostScreen: null

    spacing: 0

    BarButton {
        Layout.alignment: Qt.AlignVCenter
        visible: BluetoothState.hasAdapter
        icon: BluetoothState.hasConnectedDevice ? MaterialSymbols.bluetoothConnected : BluetoothState.isEnabled ? MaterialSymbols.bluetooth : MaterialSymbols.bluetoothDisabled
        tint: BluetoothState.hasConnectedDevice ? Theme.colors.accent : BluetoothState.isEnabled ? Theme.colors.text : Theme.colors.textFaint
        onClicked: PanelManager.toggle(PanelManager.bluetooth, root.hostScreen)
    }

    BarButton {
        Layout.alignment: Qt.AlignVCenter
        icon: NetworkState.primaryDevice === "" ? MaterialSymbols.ethernetOff : MaterialSymbols.ethernet
        tint: NetworkState.primaryDevice === "" ? Theme.colors.textFaint : Theme.colors.text
        onClicked: PanelManager.toggle(PanelManager.network, root.hostScreen)
    }

    BarButton {
        Layout.alignment: Qt.AlignVCenter
        icon: Icons.volume(Audio.volume, Audio.muted)
        tint: Audio.muted ? Theme.colors.textMuted : Theme.colors.blue
        onClicked: PanelManager.toggle(PanelManager.audio, root.hostScreen)
        onSecondaryClicked: Audio.toggleMute()
    }

    BarButton {
        Layout.alignment: Qt.AlignVCenter
        icon: PanelManager.isShowing(PanelManager.quickSettings) ? MaterialSymbols.close : MaterialSymbols.moreHoriz
        tint: Theme.colors.textSecondary
        onClicked: PanelManager.toggle(PanelManager.quickSettings, root.hostScreen)
    }
}
