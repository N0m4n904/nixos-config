import QtQuick
import QtQuick.Layouts
import qs.common.lib

Rectangle {
    id: root

    // Tile configuration
    property string icon: ""
    property string label: ""
    property string subtitle: ""
    property bool active: false
    property bool enabled: true

    // Grid sizing (in 8-column grid units)
    // Small: 2×2, Long: 4×2, Full: 8×2
    property int colSpan: 4
    property int rowSpan: 2

    // Signals - icon button
    signal iconClick()
    signal iconSecondaryClick()
    signal iconLongPress()

    // Signals - label/rest area
    signal click()
    signal secondaryClick()
    signal longPress()

    // Color palette - card stays dark, only icon changes
    readonly property color cardBackground: Qt.rgba(1, 1, 1, 0.06)
    readonly property color activeIconBg: "#C2D5E3"
    readonly property color inactiveIconBg: Qt.rgba(1, 1, 1, 0.08)
    readonly property color activeIconColor: "#1a3a4a"
    readonly property color inactiveIconColor: Theme.colors.textBright
    readonly property color labelColor: Theme.colors.textBright
    readonly property color subtitleColor: Theme.colors.textMuted

    radius: 20
    color: cardBackground
    opacity: root.enabled ? 1.0 : 0.4

    Behavior on color { ColorAnimation { duration: Theme.duration.normal } }
    Behavior on opacity { NumberAnimation { duration: Theme.duration.normal } }

    // Hover overlay (responds to label hover only, icon has its own)
    Rectangle {
        id: hoverOverlay
        anchors.fill: parent
        radius: root.radius
        color: labelMouseArea.containsMouse ? Qt.rgba(1, 1, 1, 0.04) : "transparent"
        Behavior on color { ColorAnimation { duration: Theme.duration.fast } }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 14
        anchors.topMargin: 10
        anchors.bottomMargin: 10
        spacing: 10

        // Icon container (rounded square) - click to toggle
        Rectangle {
            id: iconContainer
            Layout.preferredWidth: 40
            Layout.preferredHeight: 40
            Layout.alignment: Qt.AlignVCenter
            radius: 12
            color: root.active ? root.activeIconBg : root.inactiveIconBg
            visible: root.icon !== ""

            Behavior on color { ColorAnimation { duration: Theme.duration.normal } }

            Text {
                anchors.centerIn: parent
                text: root.icon
                color: root.active ? root.activeIconColor : root.inactiveIconColor
                font.pixelSize: 22
                font.family: Theme.iconFont

                Behavior on color { ColorAnimation { duration: Theme.duration.normal } }
            }

            MouseArea {
                id: iconMouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton

                onClicked: function(event) {
                    if (!root.enabled) return
                    if (event.button === Qt.RightButton) {
                        root.iconSecondaryClick()
                    } else {
                        root.iconClick()
                    }
                }

                onPressAndHold: {
                    if (!root.enabled) return
                    root.iconLongPress()
                }
            }

            // Icon hover effect
            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                color: iconMouseArea.containsMouse ? Qt.rgba(1, 1, 1, 0.15) : "transparent"
                Behavior on color { ColorAnimation { duration: Theme.duration.fast } }
            }
        }

        // Labels (only shown for wide tiles) - click to open panel
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.colSpan >= 4 && root.label !== ""

            ColumnLayout {
                anchors.fill: parent
                anchors.leftMargin: 2
                spacing: 1

                Item { Layout.fillHeight: true }

                Text {
                    Layout.fillWidth: true
                    text: root.label
                    color: root.labelColor
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    text: root.subtitle
                    color: root.subtitleColor
                    font.pixelSize: 11
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                    visible: root.subtitle !== ""
                }

                Item { Layout.fillHeight: true }
            }

            MouseArea {
                id: labelMouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton

                onClicked: function(event) {
                    if (!root.enabled) return
                    if (event.button === Qt.RightButton) {
                        root.secondaryClick()
                    } else {
                        root.click()
                    }
                }

                onPressAndHold: {
                    if (!root.enabled) return
                    root.longPress()
                }
            }
        }
    }
}
