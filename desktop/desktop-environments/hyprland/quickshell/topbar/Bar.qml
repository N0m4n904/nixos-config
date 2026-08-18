import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.common.lib
import "./sections"

Variants {
    model: Screens.barScreens

    PanelWindow {
        id: panel

        required property var modelData

        screen: modelData
        color: "transparent"
        implicitHeight: Theme.metrics.barHeight + Theme.metrics.barMargin * 2

        anchors {
            top: true
            left: true
            right: true
        }

        Rectangle {
            anchors.fill: parent
            anchors.margins: Theme.metrics.barMargin
            radius: height / 2
            color: Theme.colors.bar

            // The three slots are anchored rather than laid out in a row so the centre
            // stays centred on the screen instead of drifting with the side widths.
            Item {
                anchors.fill: parent
                anchors.leftMargin: Theme.metrics.padding
                anchors.rightMargin: Theme.metrics.padding

                Vitals {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                }

                Clock {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                }

                RowLayout {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Theme.metrics.gap

                    MediaControls {
                        Layout.alignment: Qt.AlignVCenter
                        Layout.rightMargin: Theme.metrics.gap
                    }

                    Tray {
                        Layout.alignment: Qt.AlignVCenter
                        hostWindow: panel
                    }

                    ClipboardButton {
                        Layout.alignment: Qt.AlignVCenter
                    }

                    BatteryIndicator {
                        Layout.alignment: Qt.AlignVCenter
                        Layout.leftMargin: Theme.metrics.gap
                        Layout.rightMargin: Theme.metrics.gap
                    }

                    StatusButtons {
                        Layout.alignment: Qt.AlignVCenter
                        hostScreen: panel.modelData
                    }
                }
            }
        }
    }
}
