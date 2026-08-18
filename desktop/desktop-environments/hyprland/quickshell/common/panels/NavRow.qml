import QtQuick
import qs.common.lib

Rectangle {
    id: root
    height: root.status ? 44 : 32
    color: hoverHandler.hovered && enabled ? Theme.colors.hover : "transparent"
    radius: 6

    property string icon
    property color iconColor: Theme.colors.text
    property string label
    property string status
    property bool enabled: true
    property bool showChevron: true
    property string trailingIcon: ""
    property color trailingIconColor: Theme.colors.accent

    signal clicked()

    Behavior on color { ColorAnimation { duration: Theme.duration.fast } }

    Row {
        anchors.left: parent.left
        anchors.leftMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.icon
            color: root.iconColor
            font.pixelSize: 18
            font.family: Theme.iconFont
            opacity: root.enabled ? 1 : 0.4
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1

            Text {
                text: root.label
                color: Theme.colors.text
                font.pixelSize: 13
                font.weight: 500
                opacity: root.enabled ? 1 : 0.4
            }

            Text {
                visible: !!root.status
                text: root.status
                color: Theme.colors.textMuted
                font.pixelSize: 11
                opacity: root.enabled ? 1 : 0.4
            }
        }
    }

    Row {
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.trailingIcon
            color: root.trailingIconColor
            font.pixelSize: 14
            font.family: Theme.iconFont
            visible: root.trailingIcon !== ""
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: MaterialSymbols.chevronRight
            color: Theme.colors.textFaint
            font.pixelSize: 18
            font.family: Theme.iconFont
            visible: root.enabled && root.showChevron
        }
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
