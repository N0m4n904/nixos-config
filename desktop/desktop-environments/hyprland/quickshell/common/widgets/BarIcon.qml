import QtQuick
import qs.common.lib

Text {
    property int size: Theme.font.iconSize

    font.family: Theme.font.icon
    font.pixelSize: size
    color: Theme.colors.text
    verticalAlignment: Text.AlignVCenter
    renderType: Text.NativeRendering
}
