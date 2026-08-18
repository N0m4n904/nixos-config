import QtQuick
import qs.common.lib

Item {
    id: root
    height: 24

    property string message

    visible: root.message !== ""

    Row {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6

        Text {
            text: MaterialSymbols.close
            color: Theme.colors.danger
            font.pixelSize: 14
            font.family: Theme.iconFont
        }

        Text {
            text: root.message
            color: Theme.colors.danger
            font.pixelSize: 12
        }
    }
}
