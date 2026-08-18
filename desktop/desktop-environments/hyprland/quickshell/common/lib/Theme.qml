pragma Singleton

import QtQuick
import Quickshell

// A superset of two vocabularies. The ported panels are authored against density
// independent helpers - Theme.spacing.md(dp) and friends - while this bar's own
// sections use fixed pixel groups, because a bar 40px tall does not benefit from
// scaling the way a 320px panel does. Both are kept rather than converting one, so
// the ported files stay byte-comparable with their upstream.
Singleton {
    readonly property string iconFont: font.icon

    // Density-independent helpers used by the ported panels.
    readonly property var radius: ({
            small: dp => dp(6),
            medium: dp => dp(8),
            large: dp => dp(14)
        })

    readonly property var spacing: ({
            xs: dp => dp(4),
            sm: dp => dp(6),
            md: dp => dp(8),
            lg: dp => dp(12)
        })

    readonly property var fontSize: ({
            xs: dp => dp(10),
            sm: dp => dp(11),
            md: dp => dp(12),
            lg: dp => dp(14),
            xl: dp => dp(16)
        })

    // Fixed metrics used by this bar's own sections.
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
        readonly property int instant: 1
        readonly property int faster: 80
        readonly property int fast: 100
        readonly property int normal: 120
        readonly property int smooth: 150
        readonly property int relaxed: 200
        readonly property int slow: 320
    }

    readonly property QtObject easing: QtObject {
        readonly property var layout: [0.0, 0.97, 0.03, 1.0, 1.0, 1.0]
        readonly property var hyprland: [0.05, 0.98, 0.56, 1.02]
    }

    readonly property QtObject colors: QtObject {
        readonly property color transparent: "transparent"

        // Semantic
        readonly property color danger: "#E74C3C"
        readonly property color warning: "#F39C12"
        readonly property color success: "#2ECC71"
        readonly property color accent: "#5EB6F7"
        readonly property color purple: "#9B59B6"
        readonly property color orange: "#E67E22"
        readonly property color blue: "#3498DB"
        readonly property color violet: "#8E44AD"
        readonly property color cyan: "#87CEEB"
        readonly property color pink: "#B57EDC"
        readonly property color teal: "#4ECDC4"
        readonly property color muted: "#808080"

        // This bar's own accents.
        readonly property color red: "#F44336"
        readonly property color green: "#4CAF50"
        readonly property color amber: "#FFC107"
        readonly property color blueDark: "#1E88E5"

        // Surfaces. The bar is deliberately well short of opaque: Hyprland blurs the
        // layer, so the transparency is what becomes frosted glass.
        readonly property color bar: "#8C121212"
        readonly property color surface: "#212121"
        readonly property color cardBackground: "#CC0A0A0A"
        readonly property color cardBackgroundBlur: "#800A0A0A"
        readonly property color shadow: "#000000"
        readonly property color shadowBorder: "#66000000"
        readonly property color hover: "#25FFFFFF"
        readonly property color pressed: "#0DFFFFFF"

        // Text
        readonly property color text: "#FFFFFF"
        readonly property color textBright: "#AAFFFFFF"
        readonly property color textSecondary: "#90FFFFFF"
        readonly property color textTertiary: "#70FFFFFF"
        readonly property color textLabel: "#60FFFFFF"
        readonly property color textMuted: "#50FFFFFF"
        readonly property color textFaint: "#40FFFFFF"

        // Separators
        readonly property color separatorStrong: "#30FFFFFF"
        readonly property color separator: "#20FFFFFF"
        readonly property color separatorSubtle: "#15FFFFFF"
        readonly property color separatorFaint: "#10FFFFFF"
    }
}
