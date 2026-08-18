import QtQuick
import qs.common.lib
import qs.common.widgets

BarButton {
    visible: Commands.clipboard !== ""
    icon: "content_paste"
    onClicked: Commands.run(Commands.clipboard)
}
