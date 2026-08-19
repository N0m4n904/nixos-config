import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import qs.common.lib
import qs.common.data
import qs.common.widgets

// Mirrors the Dash to Dock settings used under GNOME: bottom edge, centred, sized to
// its contents, above windows, with running indicators. It stays out except when a
// fullscreen window wants the whole screen, where it drops to an edge strip that
// slides it back on hover.
Variants {
    model: Screens.dockScreens

    PanelWindow {
        id: panel

        required property var modelData

        readonly property int iconSize: 48
        readonly property int tilePadding: 6
        readonly property int hideDelay: 200
        readonly property int slideDuration: 200

        // The strip left exposed while hidden. Layer surfaces get no pointer events
        // outside their own geometry, so something has to stay on screen to notice the
        // pointer arriving at the edge.
        readonly property int dockHeight: iconSize + tilePadding * 4

        // Gap left below the dock so it floats clear of the screen edge rather than
        // sitting flush against it.
        readonly property int edgeGap: Theme.metrics.barMargin * 2

        // Only a fullscreen window on this monitor's active workspace gets the dock out
        // of the way. Otherwise it stays out, rather than hiding whenever the pointer
        // leaves it.
        readonly property bool fullscreenActive: Hyprland.monitorFor(modelData)?.activeWorkspace?.hasFullscreen ?? false

        readonly property bool revealed: !fullscreenActive || pointer.hovered || hideTimer.running

        screen: modelData
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore

        // Above windows rather than merely above the desktop, so it is not covered by
        // whatever happens to be focused. It claims no space, so windows still size to
        // the whole screen and the dock floats over them.
        WlrLayershell.layer: WlrLayer.Overlay
        implicitHeight: dockHeight + edgeGap

        anchors {
            bottom: true
            left: true
            right: true
        }

        // Masked against a static item, never the dock itself: the dock's position is
        // animated, so a region tracking it is computed while it is still off screen
        // and the pointer can never enter it. This covers the dock and the gap beneath,
        // so the pointer is inside the moment the edge reveals it.
        // Fixed, never switched. Making the mask depend on whether the dock is out
        // creates a loop - the mask decides whether the pointer is seen, being seen
        // decides whether the dock is out - and it oscillates. Only the dock's position
        // changes; the region it accepts input over stays put.
        //
        // The cost is that this band keeps taking clicks while the dock is hidden. It
        // is the width of the dock and sits at the very bottom of one monitor.
        mask: Region {
            item: interactive
        }

        Timer {
            id: hideTimer

            interval: panel.hideDelay
            repeat: false
        }

        // Parents the dock rather than sitting beside it, so its hover handler keeps
        // reporting the pointer while the tiles' own mouse areas have it. As a sibling
        // it cannot: hover goes to whichever of the two is on top, so either the dock
        // loses the pointer over its own icons or the icons lose their highlight. From
        // above them there is nothing left to take it.
        //
        // Its geometry is static, unlike the dock's, which is animated: a region
        // tracking the dock is computed while the dock is still off screen, and the
        // pointer can then never enter it. This spans the dock and the gap below, so
        // the pointer is inside from the moment the edge reveals it.
        Item {
            id: interactive

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: dock.width

            HoverHandler {
                id: pointer

                onHoveredChanged: hovered ? hideTimer.stop() : hideTimer.restart()
            }

            Rectangle {
                id: dock

                anchors.horizontalCenter: parent.horizontalCenter
                width: row.implicitWidth + panel.tilePadding * 2
                height: panel.dockHeight
                radius: height / 4
                color: Theme.colors.bar
                border.width: 1
                border.color: Theme.colors.separator

                // Slides out of view rather than disappearing, so the reveal reads as
                // motion the way the GNOME dash does. Revealed it sits at the top of the
                // surface, leaving edgeGap below it.
                y: panel.revealed ? 0 : panel.implicitHeight

                Behavior on y {
                    NumberAnimation {
                        duration: panel.slideDuration
                        easing.type: Easing.OutCubic
                    }
                }

                RowLayout {
                    id: row

                    anchors.centerIn: parent
                    spacing: panel.tilePadding

                    Repeater {
                        model: Apps.items

                        delegate: Item {
                            id: tile

                            required property var modelData

                            readonly property var windows: Apps.windowsFor(modelData.entry)
                            readonly property bool running: windows.length > 0

                            Layout.alignment: Qt.AlignVCenter
                            implicitWidth: panel.iconSize + panel.tilePadding * 2
                            implicitHeight: panel.iconSize + panel.tilePadding * 2

                            Rectangle {
                                anchors.fill: parent
                                radius: Theme.metrics.padding
                                color: tilePointer.containsMouse ? Theme.colors.hover : "transparent"

                                Behavior on color {
                                    ColorAnimation {
                                        duration: Theme.duration.fast
                                    }
                                }
                            }

                            IconImage {
                                anchors.centerIn: parent
                                implicitSize: panel.iconSize
                                source: Quickshell.iconPath(tile.modelData.entry.icon, "application-x-executable")
                            }

                            // Running indicator, matching running-indicator-style DEFAULT:
                            // a dot under the icon, widened when several windows are open.
                            Rectangle {
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.bottom: parent.bottom
                                visible: tile.running
                                width: tile.windows.length > 1 ? 12 : 5
                                height: 3
                                radius: height / 2
                                color: Theme.colors.accent

                                Behavior on width {
                                    NumberAnimation {
                                        duration: Theme.duration.normal
                                    }
                                }
                            }

                            MouseArea {
                                id: tilePointer

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Apps.activate(tile.modelData.entry)
                            }
                        }
                    }

                    Rectangle {
                        Layout.alignment: Qt.AlignVCenter
                        Layout.leftMargin: panel.tilePadding
                        Layout.rightMargin: panel.tilePadding
                        implicitWidth: 1
                        implicitHeight: panel.iconSize * 0.6
                        color: Theme.colors.separator
                    }

                    BarButton {
                        Layout.alignment: Qt.AlignVCenter
                        icon: "apps"
                        tint: Theme.colors.textSecondary
                        diameter: panel.iconSize
                        iconSize: 28
                        onClicked: Commands.run(Commands.launcher)
                    }
                }
            }
        }

    }
}
