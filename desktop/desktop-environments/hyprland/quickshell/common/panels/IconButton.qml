import QtQuick
import qs.common.lib

Rectangle {
    id: root
    width: root.size
    height: root.size
    radius: root.size / 2
    color: hoverHandler.hovered ? Theme.colors.hover : "transparent"
    border.width: root.bordered ? 1 : 0
    border.color: Theme.colors.separatorStrong

    property string icon
    property int size: 32
    property bool bordered: true
    property bool enabled: true
    property color iconColor: Theme.colors.textSecondary
    property int iconSize: 20

    signal clicked()

    Behavior on color { ColorAnimation { duration: Theme.duration.fast } }

    Text {
        anchors.centerIn: parent
        text: root.icon
        color: root.iconColor
        font.pixelSize: root.iconSize
        font.family: Theme.iconFont
        opacity: root.enabled ? 1 : 0.4
    }

    HoverHandler {
        id: hoverHandler
        enabled: root.enabled
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
    }

    TapHandler {
        enabled: root.enabled
        onTapped: root.clicked()
    }
}
