import QtQuick
import qs.common.lib

// Hand-rolled rather than QtQuick.Controls' Slider: Controls drags its own styling in
// and the bar only needs a track, a fill and a drag handle.
Item {
    id: root

    property real value: 0
    property color accent: Theme.colors.blue

    signal moved(real value)

    implicitWidth: 96
    implicitHeight: 12

    function valueAt(x) {
        return Math.max(0, Math.min(1, x / width));
    }

    Rectangle {
        id: track

        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 6
        radius: height / 2
        color: Theme.colors.surface

        Rectangle {
            width: parent.width * Math.max(0, Math.min(1, root.value))
            height: parent.height
            radius: parent.radius
            color: root.accent
        }
    }

    MouseArea {
        anchors.fill: parent

        onPressed: event => root.moved(root.valueAt(event.x))
        onPositionChanged: event => {
            if (pressed)
                root.moved(root.valueAt(event.x));
        }
    }
}
