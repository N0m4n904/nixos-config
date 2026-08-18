import QtQuick
import QtQuick.Layouts
import qs.common.lib
import qs.common.data
import qs.common.widgets

RowLayout {
    id: root

    property bool expanded: false

    spacing: Theme.metrics.gap

    Reveal {
        Layout.alignment: Qt.AlignVCenter
        revealed: root.expanded

        Text {
            Layout.alignment: Qt.AlignVCenter
            text: Math.round(Audio.volume * 100)
            color: Theme.colors.textMuted
            font.pixelSize: Theme.font.small
        }

        BarSlider {
            Layout.alignment: Qt.AlignVCenter
            value: Audio.volume
            accent: Audio.muted ? Theme.colors.textMuted : Theme.colors.blue
            onMoved: level => Audio.setVolume(level)
        }
    }

    BarButton {
        Layout.alignment: Qt.AlignVCenter
        icon: Icons.volume(Audio.volume, Audio.muted)
        tint: Audio.muted ? Theme.colors.textMuted : Theme.colors.blue
        onClicked: root.expanded = !root.expanded
        onSecondaryClicked: Audio.toggleMute()
    }
}
