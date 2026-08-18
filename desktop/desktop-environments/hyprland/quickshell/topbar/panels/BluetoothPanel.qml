import QtQuick
import qs.common.state
import qs.common.panels

QtObject {
    readonly property string name: "bluetooth"
    property bool shouldShow: false
    readonly property bool show: shouldShow && BluetoothState.hasAdapter

    readonly property real panelWidth: 320
    readonly property int priority: 10

    property Component content: Component {
        BluetoothPanelContent {}
    }
}
