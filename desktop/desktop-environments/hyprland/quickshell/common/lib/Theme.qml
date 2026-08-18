pragma Singleton

import QtQuick
import Quickshell

Singleton {
    readonly property QtObject font: QtObject {
        readonly property string icon: "Material Symbols Outlined"
        readonly property int small: 11
        readonly property int normal: 13
        readonly property int iconSize: 17
    }

    readonly property QtObject metrics: QtObject {
        readonly property int barHeight: 32
        readonly property int barMargin: 4
        readonly property int buttonSize: 28
        readonly property int gap: 4
        readonly property int sectionGap: 8
        readonly property int padding: 8
    }

    readonly property QtObject duration: QtObject {
        readonly property int fast: 80
        readonly property int normal: 150
        readonly property int slow: 250
    }

    readonly property QtObject colors: QtObject {
        readonly property color bar: "#E6121212"
        readonly property color surface: "#212121"

        readonly property color text: "#FFFFFF"
        readonly property color textSecondary: "#B3FFFFFF"
        readonly property color textMuted: "#80FFFFFF"

        readonly property color hover: "#1AFFFFFF"
        readonly property color pressed: "#0DFFFFFF"

        readonly property color red: "#F44336"
        readonly property color green: "#4CAF50"
        readonly property color amber: "#FFC107"
        readonly property color blue: "#03A9F4"
        readonly property color blueDark: "#1E88E5"
    }
}
