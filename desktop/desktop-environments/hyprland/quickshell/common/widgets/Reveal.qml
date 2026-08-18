import QtQuick
import QtQuick.Layouts
import qs.common.lib

// Slides its contents out from the right, the way the eww revealers did. Collapsing to
// zero width rather than hiding keeps the surrounding layout honest, so the bar reflows
// instead of leaving a gap behind.
Item {
    id: root

    property bool revealed: false
    default property alias content: holder.data

    clip: true
    implicitWidth: revealed ? holder.implicitWidth : 0
    implicitHeight: holder.implicitHeight
    opacity: revealed ? 1 : 0
    visible: implicitWidth > 0

    Behavior on implicitWidth {
        NumberAnimation {
            duration: Theme.duration.normal
            easing.type: Easing.OutCubic
        }
    }

    Behavior on opacity {
        NumberAnimation {
            duration: Theme.duration.normal
        }
    }

    RowLayout {
        id: holder

        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.metrics.gap
    }
}
