import QtQuick
import QtQuick.Layouts
import qs.common.lib

Rectangle {
    id: root

    // Slider configuration
    property string icon: ""
    property string iconMax: ""
    property real value: 0.5
    property real minValue: 0.0
    property real maxValue: 1.0
    property bool muted: false
    property bool enabled: true

    // Grid sizing (full width, thin)
    property int colSpan: 8
    property int rowSpan: 1

    // Signals
    signal adjusted(real newValue)
    signal clicked()
    signal rightClicked()

    // Visual properties - matches Android QS slider aesthetic
    readonly property color trackBackground: Qt.rgba(1, 1, 1, 0.06)
    readonly property color trackFillColor: "#C2D5E3"
    readonly property color trackFillMuted: Qt.rgba(1, 1, 1, 0.15)
    readonly property color iconColorActive: "#1a3a4a"
    readonly property color iconColorInactive: Theme.colors.textMuted

    radius: 16
    color: trackBackground
    opacity: root.enabled ? 1.0 : 0.4

    Behavior on opacity { NumberAnimation { duration: Theme.duration.normal } }

    // Track fill
    Rectangle {
        id: fill
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: Math.max(root.radius * 2, parent.width * normalizedValue)
        radius: root.radius
        color: root.muted ? root.trackFillMuted : root.trackFillColor

        readonly property real normalizedValue: Math.max(0, Math.min(1,
            (root.value - root.minValue) / (root.maxValue - root.minValue)
        ))

        Behavior on width { NumberAnimation { duration: 50; easing.type: Easing.OutQuad } }
        Behavior on color { ColorAnimation { duration: Theme.duration.normal } }
    }

    // Hover overlay
    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: sliderArea.containsMouse ? Qt.rgba(1, 1, 1, 0.04) : "transparent"
        Behavior on color { ColorAnimation { duration: Theme.duration.fast } }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        spacing: 0

        // Left icon (min)
        Text {
            text: root.icon
            color: fill.normalizedValue > 0.08 ? root.iconColorActive : root.iconColorInactive
            font.pixelSize: 20
            font.family: Theme.iconFont
            visible: root.icon !== ""

            Behavior on color { ColorAnimation { duration: Theme.duration.normal } }
        }

        Item { Layout.fillWidth: true }

        // Right icon (max)
        Text {
            text: root.iconMax || root.icon
            color: fill.normalizedValue > 0.92 ? root.iconColorActive : root.iconColorInactive
            font.pixelSize: 20
            font.family: Theme.iconFont
            visible: root.iconMax !== "" || root.icon !== ""
            opacity: root.iconMax !== "" ? 1.0 : 0.0

            Behavior on color { ColorAnimation { duration: Theme.duration.normal } }
        }
    }

    MouseArea {
        id: sliderArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        property bool dragging: false

        onPressed: function(event) {
            if (!root.enabled) return
            if (event.button === Qt.LeftButton) {
                dragging = true
                updateValue(event.x)
            }
        }

        onReleased: function(event) {
            dragging = false
            if (event.button === Qt.RightButton) {
                root.rightClicked()
            }
        }

        onPositionChanged: function(event) {
            if (dragging && root.enabled) {
                updateValue(event.x)
            }
        }

        onClicked: function(event) {
            if (!root.enabled) return
            if (event.button === Qt.LeftButton) {
                updateValue(event.x)
            }
        }

        function updateValue(mouseX) {
            const ratio = Math.max(0, Math.min(1, mouseX / width))
            const newValue = root.minValue + ratio * (root.maxValue - root.minValue)
            root.adjusted(newValue)
        }
    }
}
