import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import qs.common.lib

RowLayout {
    id: root

    // The menu needs a window to anchor against, and a layer surface cannot discover
    // its own window, so the bar passes it down.
    property var hostWindow: null

    spacing: 0

    Repeater {
        model: SystemTray.items

        delegate: Item {
            id: entry

            required property var modelData

            Layout.alignment: Qt.AlignVCenter
            implicitWidth: Theme.metrics.buttonSize
            implicitHeight: Theme.metrics.buttonSize

            Rectangle {
                anchors.fill: parent
                radius: height / 2
                color: pointer.containsMouse ? Theme.colors.hover : "transparent"

                Behavior on color {
                    ColorAnimation {
                        duration: Theme.duration.fast
                    }
                }
            }

            IconImage {
                anchors.centerIn: parent
                implicitSize: 16
                source: entry.modelData.icon
            }

            MouseArea {
                id: pointer

                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton

                onClicked: event => {
                    if (event.button === Qt.RightButton || entry.modelData.onlyMenu)
                        menu.open();
                    else
                        entry.modelData.activate();
                }
            }

            QsMenuAnchor {
                id: menu

                menu: entry.modelData.menu
                anchor.window: root.hostWindow
                anchor.item: entry
            }
        }
    }
}
