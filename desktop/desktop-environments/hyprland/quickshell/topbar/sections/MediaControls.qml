import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.common.lib
import qs.common.data
import qs.common.widgets

RowLayout {
    id: root

    property int titleWidth: 220

    visible: Media.available
    spacing: 2

    ClippingRectangle {
        Layout.alignment: Qt.AlignVCenter
        visible: Media.artUrl !== ""
        implicitWidth: 20
        implicitHeight: 20
        radius: 4
        color: Theme.colors.surface

        Image {
            anchors.fill: parent
            source: Media.artUrl
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
        }
    }

    Text {
        Layout.alignment: Qt.AlignVCenter
        Layout.maximumWidth: root.titleWidth
        Layout.leftMargin: Theme.metrics.gap
        Layout.rightMargin: Theme.metrics.gap
        text: Media.artist ? `${Media.artist} ᛫ ${Media.title}` : Media.title
        color: Theme.colors.textSecondary
        font.pixelSize: Theme.font.small
        elide: Text.ElideRight
    }

    BarButton {
        Layout.alignment: Qt.AlignVCenter
        visible: Media.canGoPrevious
        icon: "skip_previous"
        tint: Theme.colors.textSecondary
        diameter: 22
        iconSize: Theme.font.iconSize - 2
        onClicked: Media.previous()
    }

    BarButton {
        Layout.alignment: Qt.AlignVCenter
        icon: Icons.playback(Media.playing)
        tint: Theme.colors.text
        diameter: 22
        iconSize: Theme.font.iconSize - 2
        onClicked: Media.togglePlaying()
    }

    BarButton {
        Layout.alignment: Qt.AlignVCenter
        visible: Media.canGoNext
        icon: "skip_next"
        tint: Theme.colors.textSecondary
        diameter: 22
        iconSize: Theme.font.iconSize - 2
        onClicked: Media.next()
    }

    BarButton {
        Layout.alignment: Qt.AlignVCenter
        visible: Media.loopSupported
        icon: Icons.loop(Media.loopState)
        tint: Media.loopState === "none" ? Theme.colors.textMuted : Theme.colors.blue
        diameter: 22
        iconSize: Theme.font.iconSize - 2
        onClicked: Media.cycleLoop()
    }

    BarButton {
        Layout.alignment: Qt.AlignVCenter
        visible: Media.shuffleSupported
        icon: Media.shuffle ? "shuffle_on" : "shuffle"
        tint: Media.shuffle ? Theme.colors.blue : Theme.colors.textMuted
        diameter: 22
        iconSize: Theme.font.iconSize - 2
        onClicked: Media.toggleShuffle()
    }
}
