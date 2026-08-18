import QtQuick
import Quickshell
import Quickshell.Wayland
import "../lib"

PanelWindow {
    id: root

    required property string layerName
    required property int layerOrder
    required property bool isBlurLayer
    property int wlrLayer: WlrLayer.Overlay

    readonly property string instanceId: IdGenerator.nextUniqueId()
    readonly property string namespace: isBlurLayer
        ? Namespaces.panelBlur(layerName, instanceId)
        : Namespaces.panelContent(layerName, instanceId)

    property var _layerLease: null

    WlrLayershell.layer: wlrLayer
    WlrLayershell.namespace: namespace

    Component.onCompleted: {
        _layerLease = LayerManager.obtainLease(namespace, {
            blur: isBlurLayer,
            ignoreAlpha: 0,
            order: isBlurLayer ? layerOrder + 1 : layerOrder,
            animation: "fade 0"
        })
    }

    Component.onDestruction: _layerLease?.release()
}
