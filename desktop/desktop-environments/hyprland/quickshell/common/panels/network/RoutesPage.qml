import QtQuick
import qs.common.lib

Column {
    id: root
    spacing: 0

    required property var device  // The network device object
    required property var routes  // Array of routes for this device

    signal back()

    NetworkPageHeader {
        width: parent.width
        title: root.device?.connection ?? root.device?.device ?? "Device"
        subtitle: "Routes"
        onBack: root.back()
    }

    Column {
        width: parent.width
        topPadding: 8
        spacing: 0

        Repeater {
            model: root.routes

            Column {
                width: parent.width

                // Separator between items (not before first)
                Rectangle {
                    width: parent.width
                    height: 1
                    color: Theme.colors.separatorSubtle
                    visible: index > 0
                }

                // Route row
                Item {
                    width: parent.width
                    height: routeContent.height + 16

                    Column {
                        id: routeContent
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 4

                        // Destination
                        Row {
                            spacing: 8

                            Text {
                                text: modelData.ip === "default" ? "Default Route" : modelData.ip
                                color: Theme.colors.text
                                font.pixelSize: 13
                                font.weight: modelData.ip === "default" ? 600 : 400
                            }

                            // Primary indicator for default route on this device
                            Text {
                                visible: modelData.ip === "default" && root.device?.device === modelData.dev
                                text: MaterialSymbols.primaryRoute
                                color: Theme.colors.accent
                                font.pixelSize: 12
                                font.family: Theme.iconFont
                            }
                        }

                        // Details row
                        Row {
                            spacing: 6

                            Text {
                                visible: !!modelData.via
                                text: "via " + (modelData.via ?? "")
                                color: Theme.colors.textMuted
                                font.pixelSize: 11
                            }

                            Text {
                                visible: !!modelData.via && !!modelData.src
                                text: "•"
                                color: Theme.colors.textFaint
                                font.pixelSize: 11
                            }

                            Text {
                                visible: !!modelData.src
                                text: "src " + (modelData.src ?? "")
                                color: Theme.colors.textMuted
                                font.pixelSize: 11
                            }

                            Text {
                                visible: !!modelData.metric
                                text: "•"
                                color: Theme.colors.textFaint
                                font.pixelSize: 11
                            }

                            Text {
                                visible: !!modelData.metric
                                text: "metric " + (modelData.metric ?? "")
                                color: Theme.colors.textMuted
                                font.pixelSize: 11
                            }
                        }

                        // Protocol/scope row
                        Row {
                            spacing: 6

                            Text {
                                visible: !!modelData.proto
                                text: modelData.proto ?? ""
                                color: Theme.colors.textFaint
                                font.pixelSize: 10
                            }

                            Text {
                                visible: !!modelData.proto && !!modelData.scope
                                text: "•"
                                color: Theme.colors.textFaint
                                font.pixelSize: 10
                            }

                            Text {
                                visible: !!modelData.scope
                                text: modelData.scope ?? ""
                                color: Theme.colors.textFaint
                                font.pixelSize: 10
                            }
                        }
                    }
                }
            }
        }

        // Empty state
        Item {
            width: parent.width
            height: 60
            visible: root.routes.length === 0

            Text {
                anchors.centerIn: parent
                text: "No routes"
                color: Theme.colors.textMuted
                font.pixelSize: 12
            }
        }
    }
}
