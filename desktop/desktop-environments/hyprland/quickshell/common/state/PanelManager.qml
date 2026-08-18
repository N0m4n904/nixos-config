pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    // Set by PanelContainer - array of panel instances
    property var panels: []

    // Internal: screen selected via show/toggle (may become stale on monitor disconnect)
    property var _selectedScreen: null

    // Always resolves to a valid screen — falls back to primary when _selectedScreen
    // is stale (destroyed QScreen after monitor disconnect/reconnect)
    readonly property var targetScreen: {
        if (_selectedScreen) {
            const screens = Quickshell.screens
            for (let i = 0; i < screens.length; i++) {
                if (screens[i] === _selectedScreen) return _selectedScreen
            }
        }
        return Quickshell.screens[0] ?? null
    }

    // Index constants for type-safe access (matches panels array order)
    readonly property int bluetooth: 0
    readonly property int network: 1
    readonly property int audio: 2
    readonly property int quickSettings: 3

    function show(index, screen) {
        if (screen) _selectedScreen = screen
        if (panels[index]) panels[index].shouldShow = true
    }

    function hide(index) {
        if (panels[index]) panels[index].shouldShow = false
    }

    function toggle(index, screen) {
        if (panels[index]) {
            if (!panels[index].shouldShow && screen) {
                _selectedScreen = screen
            }
            panels[index].shouldShow = !panels[index].shouldShow
        }
    }

    function hideAll() {
        for (const panel of panels) {
            if (panel) panel.shouldShow = false
        }
    }

    function isShowing(index) {
        return panels[index]?.show ?? false
    }

    readonly property bool hasVisiblePanels: panels.some(p => p?.show)
}
