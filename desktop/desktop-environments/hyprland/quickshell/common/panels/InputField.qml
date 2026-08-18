import QtQuick
import QtQuick.Controls
import qs.common.lib

Rectangle {
    id: root
    height: 40
    radius: 8
    color: Theme.colors.hover
    border.width: input.activeFocus ? 2 : 1
    border.color: input.activeFocus ? Theme.colors.accent : Theme.colors.separatorStrong

    property alias text: input.text
    property alias placeholderText: input.placeholderText
    property alias echoMode: input.echoMode
    property bool password: false
    property string trailingIcon: ""

    signal accepted()
    signal trailingIconClicked()

    Behavior on border.color { ColorAnimation { duration: Theme.duration.fast } }
    Behavior on border.width { NumberAnimation { duration: Theme.duration.fast } }

    TextField {
        id: input
        anchors.fill: parent
        anchors.margins: 1
        echoMode: root.password && !showPassword ? TextInput.Password : TextInput.Normal
        placeholderTextColor: Theme.colors.textFaint
        color: Theme.colors.text
        font.pixelSize: 13
        background: Item {}
        leftPadding: 12
        rightPadding: (root.password || root.trailingIcon !== "") ? 40 : 12

        Keys.onReturnPressed: root.accepted()
    }

    property bool showPassword: false

    Text {
        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        visible: root.password || root.trailingIcon !== ""
        text: root.password
            ? (root.showPassword ? MaterialSymbols.visibility : MaterialSymbols.visibilityOff)
            : root.trailingIcon
        color: trailingHover.hovered ? Theme.colors.textSecondary : Theme.colors.textMuted
        font.pixelSize: 18
        font.family: Theme.iconFont

        Behavior on color { ColorAnimation { duration: Theme.duration.fast } }

        HoverHandler {
            id: trailingHover
            cursorShape: Qt.PointingHandCursor
        }

        TapHandler {
            onTapped: {
                if (root.password) {
                    root.showPassword = !root.showPassword
                } else {
                    root.trailingIconClicked()
                }
            }
        }
    }

    function activate() {
        input.forceActiveFocus()
    }
}
