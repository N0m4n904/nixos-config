import QtQuick
import QtQuick.Layouts
import qs.common.lib
import qs.common.data
import qs.common.state
import qs.common.widgets

// Openers for the ported panels. PanelManager addresses panels by fixed index, so
// these constants are the contract with topbar/components/PanelContainer.
RowLayout {
    id: root

    // The bar surface these sit on, so a panel opens against the right monitor.
    property var hostScreen: null

    spacing: 0

    BarButton {
        Layout.alignment: Qt.AlignVCenter
        icon: "bluetooth"
        tint: PanelManager.isShowing(PanelManager.bluetooth) ? Theme.colors.text : Theme.colors.textSecondary
        onClicked: PanelManager.toggle(PanelManager.bluetooth, root.hostScreen)
    }

    BarButton {
        Layout.alignment: Qt.AlignVCenter
        icon: "lan"
        tint: PanelManager.isShowing(PanelManager.network) ? Theme.colors.text : Theme.colors.textSecondary
        onClicked: PanelManager.toggle(PanelManager.network, root.hostScreen)
    }

    BarButton {
        Layout.alignment: Qt.AlignVCenter
        icon: Icons.volume(Audio.volume, Audio.muted)
        tint: PanelManager.isShowing(PanelManager.audio) ? Theme.colors.text : Audio.muted ? Theme.colors.textMuted : Theme.colors.blue
        onClicked: PanelManager.toggle(PanelManager.audio, root.hostScreen)
        onSecondaryClicked: Audio.toggleMute()
    }

    BarButton {
        Layout.alignment: Qt.AlignVCenter
        icon: PanelManager.isShowing(PanelManager.quickSettings) ? "close" : "tune"
        tint: Theme.colors.textSecondary
        onClicked: PanelManager.toggle(PanelManager.quickSettings, root.hostScreen)
    }
}
