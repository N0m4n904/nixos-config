import QtQuick
import qs.common.lib

Column {
    spacing: 2

    property string label
    property string value
    property color valueColor: Theme.colors.text

    Text {
        text: label
        color: Theme.colors.textMuted
        font.pixelSize: 12
    }

    Text {
        text: value
        color: valueColor
        font.pixelSize: 12
    }
}
