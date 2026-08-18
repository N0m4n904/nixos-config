pragma Singleton

import QtQuick
import Quickshell

Singleton {
    // Which screen the bar belongs on, injected by the Nix module. Matched against the
    // connector name or any part of the monitor's model, so it survives the connectors
    // being renumbered when cables move ports. Empty means every screen.
    readonly property string barScreen: Quickshell.env("QS_BAR_SCREEN") ?? ""

    readonly property var barScreens: barScreen === "" ? Quickshell.screens : [...Quickshell.screens].filter(screen => screen.name === barScreen || (screen.model ?? "").includes(barScreen))
}
