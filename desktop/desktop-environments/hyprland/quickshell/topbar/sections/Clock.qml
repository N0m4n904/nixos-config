import QtQuick
import QtQuick.Layouts
import qs.common.lib

RowLayout {
    spacing: Theme.metrics.gap

    Text {
        Layout.alignment: Qt.AlignVCenter
        text: Time.clock
        color: Theme.colors.text
        font.pixelSize: Theme.font.normal
        font.weight: Font.DemiBold
    }

    Text {
        Layout.alignment: Qt.AlignVCenter
        text: Time.date
        color: Theme.colors.textMuted
        font.pixelSize: Theme.font.small
    }
}
