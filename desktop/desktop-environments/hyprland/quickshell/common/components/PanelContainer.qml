import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../lib"
import "../state"

Item {
    id: root

    property bool widgetMode: false
    property var panels: []
    required property var dp

    readonly property var panelScreen: PanelManager.targetScreen
    readonly property real screenWidth: panelScreen?.width ?? 1920
    readonly property real topOffset: widgetMode ? 66 : 48
    readonly property real edgeMargin: 8
    readonly property real panelGap: 8

    Component.onCompleted: {
        PanelManager.panels = panels
    }

    Connections {
        target: Hyprland
        function onActiveToplevelChanged() {
            if (panels.some(p => p.show) && Hyprland.activeToplevel) {
                PanelManager.hideAll()
            }
        }
    }

    Repeater {
        model: root.panels

        Item {
            id: panelItem
            required property QtObject modelData
            required property int index

            readonly property int layerOrder: index

            PanelSlot {
                id: slot
                panel: panelItem.modelData
                index: panelItem.index
                panels: root.panels
                dp: root.dp
                screenWidth: root.screenWidth
                topOffset: root.topOffset
                edgeMargin: root.edgeMargin
                panelGap: root.panelGap

                onCloseRequested: panelItem.modelData.shouldShow = false
            }

            LazyLoader {
                loading: true

                DynamicLayer {
                    layerName: panelItem.modelData.name
                    layerOrder: panelItem.layerOrder
                    isBlurLayer: true
                    screen: root.panelScreen
                    // Upstream keeps this mapped permanently to dodge a fade
                    // animation. A mapped, output-sized overlay is a focus hazard, and
                    // the layer's lease already sets "fade 0", so there is no animation
                    // to dodge.
                    visible: slot.panelVisible

                    anchors { top: true; bottom: true; left: true; right: true }
                    color: "transparent"
                    exclusionMode: ExclusionMode.Ignore
                    mask: Region {}

                    Item {
                        visible: slot.panelVisible
                        x: slot.panelXTarget
                        y: root.topOffset
                        width: slot.panelWidth
                        height: slot.panelHeight

                        Behavior on x {
                            NumberAnimation { duration: Theme.duration.slow; easing.type: Easing.OutQuart }
                        }
                        Behavior on height {
                            NumberAnimation { duration: Theme.duration.normal; easing.type: Easing.OutCubic }
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: 14
                            color: Theme.colors.cardBackgroundBlur
                        }
                    }
                }
            }

            LazyLoader {
                loading: true

                DynamicLayer {
                    id: contentWindow
                    layerName: panelItem.modelData.name
                    layerOrder: panelItem.layerOrder
                    isBlurLayer: false
                    screen: root.panelScreen
                    // Unmapped while closed, so a hidden panel cannot hold keyboard
                    // focus or sit between a click and the window beneath it.
                    visible: slot.panelVisible

                    // Needed while open so the wifi password field can be typed into.
                    // Safe now that the layer is unmapped whenever no panel is shown.
                    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

                    HyprlandFocusGrab {
                        // Upstream gates this on widgetMode, which leaves panels in
                        // the bar with no way to dismiss but the button that opened
                        // them. The grab closes the panel on the first click outside
                        // and hands focus straight back.
                        active: panelItem.modelData.show
                        windows: [contentWindow]
                        onCleared: panelItem.modelData.shouldShow = false
                    }

                    anchors { top: true; bottom: true; left: true; right: true }
                    color: "transparent"
                    exclusionMode: ExclusionMode.Ignore

                    Region { id: contentRegion; item: contentItem }
                    Region { id: noInputRegion }
                    mask: slot.panelVisible ? contentRegion : noInputRegion

                    Item {
                        id: contentItem
                        visible: slot.panelVisible
                        x: slot.panelXTarget
                        y: root.topOffset
                        width: slot.panelWidth
                        height: slot.panelHeight
                        focus: true

                        Keys.onEscapePressed: panelItem.modelData.shouldShow = false

                        onXChanged: slot.currentPanelX = x

                        Behavior on x {
                            NumberAnimation { duration: Theme.duration.slow; easing.type: Easing.OutQuart }
                        }
                        Behavior on height {
                            NumberAnimation { duration: Theme.duration.normal; easing.type: Easing.OutCubic }
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: 14
                            color: "transparent"

                            layer.enabled: true
                            layer.effect: MultiEffect {
                                shadowEnabled: true
                                shadowColor: Theme.colors.shadow
                                shadowBlur: 0.6
                                shadowVerticalOffset: root.dp(6)
                                shadowHorizontalOffset: 0
                                shadowOpacity: 0.5
                            }
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: 14
                            color: Qt.rgba(0.04, 0.04, 0.04, 0.1)
                            border.width: 1
                            border.color: Theme.colors.separatorFaint
                        }

                        Loader {
                            id: contentLoader
                            anchors.fill: parent
                            anchors.margins: 12
                            sourceComponent: slot.contentComponent

                            onItemChanged: slot.bindContentItem(item)
                            onLoaded: slot.handleContentLoaded(item)
                        }
                    }
                }
            }
        }
    }
}
