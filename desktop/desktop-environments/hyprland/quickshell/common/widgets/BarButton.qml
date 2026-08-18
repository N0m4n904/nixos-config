import QtQuick
import qs.common.lib

Rectangle {
    id: root

    property string icon
    property color tint: Theme.colors.text
    property int diameter: Theme.metrics.buttonSize
    property int iconSize: Theme.font.iconSize

    signal clicked
    signal secondaryClicked

    implicitWidth: diameter
    implicitHeight: diameter
    radius: height / 2
    color: pointer.pressed ? Theme.colors.pressed : pointer.containsMouse ? Theme.colors.hover : "transparent"

    Behavior on color {
        ColorAnimation {
            duration: Theme.duration.fast
        }
    }

    BarIcon {
        anchors.centerIn: parent
        text: root.icon
        color: root.tint
        size: root.iconSize
    }

    MouseArea {
        id: pointer

        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: event => event.button === Qt.RightButton ? root.secondaryClicked() : root.clicked()
    }
}
