import QtQuick
import QtQuick.Layouts
import qs.common.lib

RowLayout {
    id: root

    property string icon
    property string value
    property color tint: Theme.colors.text

    spacing: 2

    BarIcon {
        Layout.alignment: Qt.AlignVCenter
        text: root.icon
        color: root.tint
        size: Theme.font.normal + 2
    }

    Text {
        Layout.alignment: Qt.AlignVCenter
        text: root.value
        color: root.tint
        font.pixelSize: Theme.font.normal
    }
}
