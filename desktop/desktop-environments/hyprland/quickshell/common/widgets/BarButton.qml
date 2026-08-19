import QtQuick
import qs.common.lib

Rectangle {
    id: root

    property string icon
    property color tint: Theme.colors.text
    property int diameter: Theme.metrics.buttonSize
    property int iconSize: Theme.font.iconSize

    // Hovering normally just lifts the background a little and leaves the icon alone.
    // Setting these turns it into the filled treatment the power buttons use, where
    // the button floods with its own colour and the icon inverts to read against it.
    property color hoverFill: Theme.colors.hover
    property color hoverTint: tint
    property int cornerRadius: -1

    // Lets a container know the pointer is on this button, which it cannot learn from
    // its own handlers once this one has taken the hover.
    readonly property alias hovered: pointer.containsMouse

    signal clicked
    signal secondaryClicked

    implicitWidth: diameter
    implicitHeight: diameter
    radius: cornerRadius < 0 ? height / 2 : cornerRadius
    color: pointer.pressed ? Theme.colors.pressed : pointer.containsMouse ? hoverFill : "transparent"

    Behavior on color {
        ColorAnimation {
            duration: Theme.duration.fast
        }
    }

    BarIcon {
        anchors.centerIn: parent
        text: root.icon
        color: pointer.containsMouse ? root.hoverTint : root.tint
        size: root.iconSize

        Behavior on color {
            ColorAnimation {
                duration: Theme.duration.fast
            }
        }
    }

    MouseArea {
        id: pointer

        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: event => event.button === Qt.RightButton ? root.secondaryClicked() : root.clicked()
    }
}
