import QtQuick
import qs.common.lib

Item {
    id: root
    height: 44

    property string title
    property string subtitle

    signal back()

    Item {
        anchors.fill: parent
        anchors.topMargin: -2
        anchors.bottomMargin: 6

        IconButton {
            id: backButton
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            icon: MaterialSymbols.chevronLeft
            onClicked: root.back()
        }

        Column {
            anchors.left: backButton.right
            anchors.leftMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            spacing: root.subtitle ? 1 : 0

            Text {
                text: root.title
                color: Theme.colors.text
                font.pixelSize: root.subtitle ? 13 : 15
                font.weight: 600
            }

            Text {
                visible: !!root.subtitle
                text: root.subtitle
                color: Theme.colors.textMuted
                font.pixelSize: 11
            }
        }
    }
}
