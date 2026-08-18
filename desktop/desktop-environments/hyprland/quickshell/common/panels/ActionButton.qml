import QtQuick
import qs.common.lib

Rectangle {
    id: root
    height: 40
    radius: 8

    property string text
    property string variant: "primary"  // "primary", "danger", "outline"
    property bool loading: false
    property bool enabled: true
    property string icon: ""

    signal clicked()

    color: {
        if (root.variant === "outline") return "transparent"
        if (!root.enabled) return Theme.colors.hover

        const baseColor = root.variant === "danger" ? Theme.colors.danger : Theme.colors.accent
        if (root.loading) return baseColor
        return hoverHandler.hovered ? Qt.lighter(baseColor, 1.1) : baseColor
    }

    opacity: {
        if (!root.enabled) return 0.5
        if (root.variant === "danger" && !root.loading) return hoverHandler.hovered ? 1 : 0.85
        return 1
    }

    border.width: root.variant === "outline" ? 1 : 0
    border.color: {
        if (root.variant !== "outline") return "transparent"
        return hoverHandler.hovered ? Theme.colors.danger : Theme.colors.separatorStrong
    }

    Behavior on color { ColorAnimation { duration: Theme.duration.fast } }
    Behavior on opacity { NumberAnimation { duration: Theme.duration.fast } }
    Behavior on border.color { ColorAnimation { duration: Theme.duration.fast } }

    Row {
        anchors.centerIn: parent
        spacing: 8

        Text {
            visible: root.loading || root.icon !== ""
            anchors.verticalCenter: parent.verticalCenter
            text: root.icon !== "" ? root.icon : MaterialSymbols.refresh
            color: root.variant === "outline"
                ? (hoverHandler.hovered ? Theme.colors.danger : Theme.colors.textSecondary)
                : "#FFFFFF"
            font.pixelSize: 16
            font.family: Theme.iconFont

            SequentialAnimation on opacity {
                running: root.loading
                loops: Animation.Infinite
                NumberAnimation { to: 0.3; duration: 400 }
                NumberAnimation { to: 1; duration: 400 }
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.text
            color: root.variant === "outline"
                ? (hoverHandler.hovered ? Theme.colors.danger : Theme.colors.textSecondary)
                : "#FFFFFF"
            font.pixelSize: 13
            font.weight: 500

            Behavior on color { ColorAnimation { duration: Theme.duration.fast } }
        }
    }

    HoverHandler {
        id: hoverHandler
        enabled: root.enabled && !root.loading
        cursorShape: (root.enabled && !root.loading) ? Qt.PointingHandCursor : Qt.ArrowCursor
    }

    TapHandler {
        enabled: root.enabled && !root.loading
        onTapped: root.clicked()
    }
}
