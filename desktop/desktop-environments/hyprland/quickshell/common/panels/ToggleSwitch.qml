import QtQuick
import qs.common.lib

Rectangle {
    id: root
    width: 40
    height: 22
    radius: 11
    color: root.checked ? root.accentColor : Theme.colors.separatorStrong

    property bool checked: false
    property bool enabled: true
    property color accentColor: Theme.colors.accent

    signal toggled()

    Behavior on color { ColorAnimation { duration: Theme.duration.fast } }

    Rectangle {
        x: root.checked ? parent.width - width - 3 : 3
        anchors.verticalCenter: parent.verticalCenter
        width: 16
        height: 16
        radius: 8
        color: "#FFFFFF"

        Behavior on x { NumberAnimation { duration: Theme.duration.fast } }
    }

    HoverHandler {
        enabled: root.enabled
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
    }

    TapHandler {
        enabled: root.enabled
        onTapped: root.toggled()
    }
}
