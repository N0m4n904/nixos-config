pragma Singleton

import QtQuick
import Quickshell

Singleton {
    // Which screen the bar belongs on, injected by the Nix module. Matched against the
    // connector name or any part of the monitor's model, so it survives the connectors
    // being renumbered when cables move ports. Empty means every screen.
    readonly property string barScreen: Quickshell.env("QS_BAR_SCREEN") ?? ""

    readonly property var barScreens: screensMatching(barScreen)

    // Dash to Dock is set to a single monitor here (multi-monitor false, pinned to a
    // connector), so the dock follows the same rule as the bar.
    readonly property string dockScreen: Quickshell.env("QS_DOCK_SCREEN") ?? ""
    readonly property var dockScreens: screensMatching(dockScreen)

    function screensMatching(selector) {
        if (selector === "")
            return Quickshell.screens;

        return [...Quickshell.screens].filter(screen => screen.name === selector || (screen.model ?? "").includes(selector));
    }
}
