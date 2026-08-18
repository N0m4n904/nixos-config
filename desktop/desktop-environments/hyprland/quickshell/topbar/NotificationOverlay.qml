import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import Quickshell.Services.Notifications
import qs.common.lib
import qs.common.data
import qs.common.widgets

// A single surface on the focused monitor rather than one per screen, so a toast is
// not duplicated across three displays.
PanelWindow {
    id: overlay

    readonly property int toastWidth: 380

    screen: [...Quickshell.screens].find(candidate => Hyprland.monitorFor(candidate)?.focused) ?? Quickshell.screens[0] ?? null

    visible: Notifications.list.length > 0
    color: "transparent"
    implicitWidth: toastWidth + Theme.metrics.barMargin * 2
    implicitHeight: Math.max(1, stack.implicitHeight + Theme.metrics.barMargin)

    // The bar already claims the top strip; the toasts must not claim another one or
    // every window on the monitor would be pushed down while a notification is up.
    exclusionMode: ExclusionMode.Ignore

    anchors {
        top: true
        right: true
    }

    margins.top: Theme.metrics.barHeight + Theme.metrics.barMargin * 2

    ColumnLayout {
        id: stack

        anchors.right: parent.right
        anchors.top: parent.top
        anchors.rightMargin: Theme.metrics.barMargin
        width: overlay.toastWidth
        spacing: Theme.metrics.gap

        Repeater {
            model: Notifications.list

            delegate: Rectangle {
                id: toast

                required property var modelData

                readonly property color accent: modelData.urgency === NotificationUrgency.Critical ? Theme.colors.red : modelData.urgency === NotificationUrgency.Low ? Theme.colors.textMuted : Theme.colors.blue

                Layout.fillWidth: true
                implicitHeight: body.implicitHeight + Theme.metrics.padding * 2
                radius: Theme.metrics.padding
                color: Theme.colors.bar

                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: 3
                    radius: width / 2
                    color: toast.accent
                }

                RowLayout {
                    id: body

                    anchors.fill: parent
                    anchors.margins: Theme.metrics.padding
                    anchors.leftMargin: Theme.metrics.padding + 4
                    spacing: Theme.metrics.padding

                    IconImage {
                        Layout.alignment: Qt.AlignTop
                        visible: toast.modelData.appIcon !== ""
                        implicitSize: 24
                        source: toast.modelData.appIcon
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            Layout.fillWidth: true
                            text: toast.modelData.summary
                            color: Theme.colors.text
                            font.pixelSize: Theme.font.normal
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }

                        Text {
                            Layout.fillWidth: true
                            visible: toast.modelData.body !== ""
                            text: toast.modelData.body
                            color: Theme.colors.textSecondary
                            font.pixelSize: Theme.font.small
                            textFormat: Text.StyledText
                            wrapMode: Text.WordWrap
                            maximumLineCount: 4
                            elide: Text.ElideRight
                        }

                        Text {
                            Layout.fillWidth: true
                            visible: toast.modelData.appName !== ""
                            text: toast.modelData.appName
                            color: Theme.colors.textMuted
                            font.pixelSize: Theme.font.small - 1
                            elide: Text.ElideRight
                        }
                    }

                    BarButton {
                        Layout.alignment: Qt.AlignTop
                        icon: "close"
                        tint: Theme.colors.textMuted
                        diameter: 20
                        iconSize: Theme.font.iconSize - 3
                        onClicked: toast.modelData.dismiss()
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton
                    onClicked: toast.modelData.dismiss()
                }

                // Servers may pass 0 ("never expire") or -1 ("server decides"); neither
                // should leave a toast on screen forever.
                Timer {
                    interval: toast.modelData.expireTimeout > 0 ? toast.modelData.expireTimeout : 6000
                    running: true
                    onTriggered: toast.modelData.expire()
                }
            }
        }
    }
}
