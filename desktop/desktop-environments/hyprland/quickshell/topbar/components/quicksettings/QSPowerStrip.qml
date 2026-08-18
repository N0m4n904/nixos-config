import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Quickshell.Hyprland
import qs.common.lib

Rectangle {
    id: root

    // Grid sizing
    property int colSpan: 8
    property int rowSpan: 2

    // Visual properties
    readonly property color background: Qt.rgba(1, 1, 1, 0.06)
    readonly property color buttonBg: Qt.rgba(1, 1, 1, 0.08)
    readonly property color buttonHoverBg: Qt.rgba(1, 1, 1, 0.15)

    radius: 20
    color: background

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 12
        spacing: 8

        // Label
        Text {
            text: "Power"
            color: Theme.colors.textBright
            font.pixelSize: 13
            font.weight: Font.DemiBold
        }

        Item { Layout.fillWidth: true }

        // Action buttons
        Row {
            spacing: 8

            // Logout
            Rectangle {
                width: 40
                height: 40
                radius: 12
                color: logoutHover.containsMouse ? root.buttonHoverBg : root.buttonBg

                Behavior on color { ColorAnimation { duration: Theme.duration.fast } }

                Text {
                    anchors.centerIn: parent
                    text: MaterialSymbols.logout
                    color: logoutHover.containsMouse ? Theme.colors.warning : Theme.colors.textBright
                    font.pixelSize: 20
                    font.family: Theme.iconFont

                    Behavior on color { ColorAnimation { duration: Theme.duration.fast } }
                }

                MouseArea {
                    id: logoutHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Hyprland.dispatch("exit")
                }
            }

            // Restart
            Rectangle {
                width: 40
                height: 40
                radius: 12
                color: restartHover.containsMouse ? root.buttonHoverBg : root.buttonBg

                Behavior on color { ColorAnimation { duration: Theme.duration.fast } }

                Text {
                    anchors.centerIn: parent
                    text: MaterialSymbols.restart
                    color: restartHover.containsMouse ? Theme.colors.blue : Theme.colors.textBright
                    font.pixelSize: 20
                    font.family: Theme.iconFont

                    Behavior on color { ColorAnimation { duration: Theme.duration.fast } }
                }

                MouseArea {
                    id: restartHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: rebootProcess.running = true
                }

                Process {
                    id: rebootProcess
                    command: ["systemctl", "reboot"]
                }
            }

            // Shutdown
            Rectangle {
                width: 40
                height: 40
                radius: 12
                color: shutdownHover.containsMouse ? root.buttonHoverBg : root.buttonBg

                Behavior on color { ColorAnimation { duration: Theme.duration.fast } }

                Text {
                    anchors.centerIn: parent
                    text: MaterialSymbols.power
                    color: shutdownHover.containsMouse ? Theme.colors.danger : Theme.colors.textBright
                    font.pixelSize: 20
                    font.family: Theme.iconFont

                    Behavior on color { ColorAnimation { duration: Theme.duration.fast } }
                }

                MouseArea {
                    id: shutdownHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: poweroffProcess.running = true
                }

                Process {
                    id: poweroffProcess
                    command: ["systemctl", "poweroff"]
                }
            }
        }
    }
}
