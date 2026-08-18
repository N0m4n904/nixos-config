import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.common.lib
import qs.common.state
import "tiles"

Item {
    id: root

    property bool show: false
    property bool widgetMode: false
    property real panelWidth: 320
    property real panelMargin: 8

    signal closeRequested()
    signal openWifiPanel()
    signal openBluetoothPanel()

    // Functions for content to call (avoids Component scope issues)
    function requestWifiPanel() {
        closeRequested()
        openWifiPanel()
    }
    function requestBluetoothPanel() {
        closeRequested()
        openBluetoothPanel()
    }

    readonly property var panelScreen: QsWindow.window?.screen ?? null
    function dp(value) { return shell.dp(value, panelScreen) }

    // Track content height from inside the LazyLoader
    property real contentHeight: 200

    // Dimensions
    readonly property real screenWidth: panelScreen?.width ?? 1920
    readonly property real topOffset: widgetMode ? 66 : 48
    readonly property real panelHeight: contentHeight + 24

    // Animation targets
    readonly property real panelXVisible: screenWidth - panelWidth - panelMargin
    readonly property real panelXHidden: screenWidth
    readonly property real panelXTarget: show ? panelXVisible : panelXHidden

    property real currentPanelX: panelXHidden
    readonly property bool panelVisible: show || currentPanelX < panelXHidden - 1

    // Close on window focus change
    Connections {
        target: Hyprland
        function onActiveToplevelChanged() {
            if (root.show && Hyprland.activeToplevel) {
                root.closeRequested()
            }
        }
    }

    // Main panel window
    LazyLoader {
        loading: true

        PanelWindow {
            id: panelWindow
            screen: QsWindow.window?.screen ?? null
            visible: root.panelVisible

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: Namespaces.overlayPanels
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

            HyprlandFocusGrab {
                active: root.widgetMode && root.show
                windows: [panelWindow]
                onCleared: root.closeRequested()
            }

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            mask: Region { item: panelContent }

            Item {
                id: panelContent
                x: root.panelXTarget
                y: root.topOffset
                width: root.panelWidth
                height: root.panelHeight
                focus: true

                Keys.onEscapePressed: root.closeRequested()

                Behavior on x {
                    NumberAnimation {
                        duration: Theme.duration.slow
                        easing.type: Easing.OutQuart
                    }
                }

                Behavior on height {
                    NumberAnimation {
                        duration: Theme.duration.normal
                        easing.type: Easing.OutCubic
                    }
                }

                onXChanged: root.currentPanelX = x

                // Shadow
                Rectangle {
                    anchors.fill: parent
                    radius: 20
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

                // Background
                Rectangle {
                    anchors.fill: parent
                    radius: 20
                    color: Qt.rgba(0.04, 0.04, 0.04, 0.1)
                    border.width: 1
                    border.color: Theme.colors.separatorFaint
                }

                // Content
                ColumnLayout {
                    id: contentColumn
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 8

                    onImplicitHeightChanged: root.contentHeight = implicitHeight
                    Component.onCompleted: root.contentHeight = implicitHeight

                    // Row 1: WiFi + Bluetooth (half each)
                    RowLayout {
                        id: wifiBtRow
                        Layout.fillWidth: true
                        spacing: 8
                        visible: wifiLoader.active || bluetoothLoader.active

                        Loader {
                            id: wifiLoader
                            active: NetworkState.devices.some(d => d.type === "wifi" && d.state !== "unmanaged")
                            Layout.fillWidth: true
                            Layout.preferredHeight: active ? 64 : 0
                            sourceComponent: WifiTile {
                                onPanelRequested: root.requestWifiPanel()
                            }
                        }

                        Loader {
                            id: bluetoothLoader
                            active: BluetoothState.hasAdapter
                            Layout.fillWidth: true
                            Layout.preferredHeight: active ? 64 : 0
                            sourceComponent: BluetoothTile {
                                onPanelRequested: root.requestBluetoothPanel()
                            }
                        }
                    }

                    // Row 2: Ethernet
                    EthernetTile {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 64
                    }

                    // Row 3: Brightness slider
                    BrightnessSlider {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 48
                    }

                    // Row 4: Volume slider
                    VolumeSlider {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 48
                    }

                    // Row 5: Power strip
                    QSPowerStrip {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 64
                    }
                }
            }
        }
    }

    // Blur layer
    LazyLoader {
        loading: true

        PanelWindow {
            screen: QsWindow.window?.screen ?? null
            visible: root.panelVisible

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: Namespaces.overlayPanelsBlur

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            mask: Region {}

            Item {
                x: root.panelXTarget
                y: root.topOffset
                width: root.panelWidth
                height: root.panelHeight

                Behavior on x {
                    NumberAnimation {
                        duration: Theme.duration.slow
                        easing.type: Easing.OutQuart
                    }
                }

                Behavior on height {
                    NumberAnimation {
                        duration: Theme.duration.normal
                        easing.type: Easing.OutCubic
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    radius: 20
                    color: Theme.colors.cardBackgroundBlur
                }
            }
        }
    }
}
