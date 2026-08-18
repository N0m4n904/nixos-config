import QtQuick
import qs.common.panels

QtObject {
    readonly property string name: "audio"
    property bool shouldShow: false
    readonly property bool show: shouldShow

    readonly property real panelWidth: 320
    readonly property int priority: 10

    property Component content: Component {
        AudioPanelContent {}
    }
}
