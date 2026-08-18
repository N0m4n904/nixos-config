import QtQuick
import "../components/quicksettings"

QtObject {
    readonly property string name: "quicksettings"
    property bool shouldShow: false
    readonly property bool show: shouldShow

    readonly property real panelWidth: 320
    readonly property int priority: 0

    property Component content: Component {
        QuickSettingsPanelContent {}
    }
}
