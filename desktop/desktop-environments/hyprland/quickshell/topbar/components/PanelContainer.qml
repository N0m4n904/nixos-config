import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.common.components as Common
import "../panels"

Common.PanelContainer {
    id: root

    // Panel metrics are authored against a 92 PPI reference, so they scale by the real
    // density of whichever monitor the panel opens on. Falls back to 1:1 when Hyprland
    // reports no physical size for the output.
    dp: value => {
        const monitor = Hyprland.monitorFor(panelScreen);
        const physicalWidth = monitor?.lastIpcObject?.physicalWidth ?? 0;
        const ppi = physicalWidth > 0 && panelScreen ? panelScreen.width / (physicalWidth / 25.4) : 92;
        return value * (ppi / 92);
    }

    QuickSettingsPanel {
        id: qsPanel
    }

    NetworkPanel {
        id: networkPanel
    }

    AudioPanel {
        id: audioPanel
    }

    BluetoothPanel {
        id: btPanel
    }

    // Order is load-bearing: PanelManager addresses these by fixed index
    // (bluetooth 0, network 1, audio 2, quickSettings 3).
    panels: [btPanel, networkPanel, audioPanel, qsPanel]
}
