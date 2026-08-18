import QtQuick
import Quickshell.Services.Pipewire
import Quickshell.Io
import qs.common.lib

Item {
    id: root
    implicitHeight: contentColumn.implicitHeight

    function reset() {
        _expandedSinks = ({})
    }

    // Track which device sections have their picker open (sink.id → bool)
    property var _expandedSinks: ({})
    property int _expandedVersion: 0

    function toggleExpanded(sinkId) {
        const copy = Object.assign({}, _expandedSinks)
        if (copy[sinkId]) delete copy[sinkId]
        else copy[sinkId] = true
        _expandedSinks = copy
        _expandedVersion++
    }

    function isExpanded(sinkId) {
        _expandedVersion
        return !!_expandedSinks[sinkId]
    }

    // Deferred snapshots — Qt.callLater ensures we run after Pipewire's destruction
    // callbacks complete. All data is built from a single clean Pipewire.nodes.values
    // snapshot, and link groups are cross-referenced against live node IDs only.
    // outputStreams is set FIRST so that assignableStreams bindings (triggered by
    // sinkStreamsMap change) read clean data, not stale references to destroyed nodes.
    property var outputStreams: []
    property var sinks: []
    property var sinkStreamsMap: ({})
    readonly property var defaultSink: Pipewire.defaultAudioSink

    function _refresh() {
        const nodes = Pipewire.nodes.values
        const liveById = new Map()
        for (const n of nodes) {
            if (n) liveById.set(n.id, n)
        }

        const newStreams = nodes.filter(n => n && n.isStream && n.audio && n.isSink)
        const newSinks = nodes.filter(n => n && !n.isStream && n.isSink)

        // Build sinkStreamsMap using only live node references
        const map = {}
        for (const sink of newSinks) map[sink.id] = []
        for (const lg of Pipewire.linkGroups.values) {
            const src = liveById.get(lg?.source?.id)
            const tgt = liveById.get(lg?.target?.id)
            if (!src || !tgt) continue
            if (src.isStream && src.audio && !tgt.isStream && tgt.isSink) {
                if (!map[tgt.id]) map[tgt.id] = []
                map[tgt.id].push(src)
            }
        }

        // Order matters: outputStreams first so assignableStreams bindings
        // (triggered by sinkStreamsMap change) read clean data, not the old
        // outputStreams array which may still reference the destroyed node.
        root.outputStreams = newStreams
        root.sinkStreamsMap = map
        root.sinks = newSinks
    }

    Connections {
        target: Pipewire.nodes
        function onValuesChanged() { Qt.callLater(root._refresh) }
    }

    Connections {
        target: Pipewire.linkGroups
        function onValuesChanged() { Qt.callLater(root._refresh) }
    }

    Component.onCompleted: _refresh()

    PwObjectTracker {
        objects: [...root.outputStreams, ...root.sinks, root.defaultSink].filter(n => n)
    }

    Process {
        id: metadataProc
        running: false
        onExited: (code, status) => {
            if (code !== 0) console.warn("[AudioPanel] pw-metadata failed:", code)
        }
    }

    function assignStreamToSink(stream, sink) {
        metadataProc.command = ["pw-metadata", "-n", "default", String(stream.id),
            "target.node", JSON.stringify({name: sink.name}), "Spa:String:JSON"]
        metadataProc.running = true
    }

    function kickStream(stream) {
        metadataProc.command = ["pw-metadata", "-n", "default", "-d", String(stream.id), "target.node"]
        metadataProc.running = true
    }

    Column {
        id: contentColumn
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 0

        // Header
        Item {
            width: parent.width
            height: 32

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 2
                anchors.verticalCenter: parent.verticalCenter
                text: "Audio"
                color: Theme.colors.text
                font.pixelSize: 15
                font.weight: 600
            }
        }

        // Device sections
        Column {
            width: parent.width
            spacing: 4

            Repeater {
                model: root.sinks

                Rectangle {
                    id: deviceSection
                    required property var modelData
                    required property int index
                    width: parent.width
                    radius: 8
                    color: Theme.colors.separatorFaint
                    implicitHeight: deviceColumn.implicitHeight

                    readonly property var sink: modelData
                    readonly property bool isDefault: sink === root.defaultSink
                    readonly property var streams: root.sinkStreamsMap[sink.id] ?? []
                    readonly property bool isExpanded: root.isExpanded(sink.id)

                    // Available streams for the picker: streams not already on this device
                    readonly property var assignableStreams: {
                        const onThisSink = new Set(deviceSection.streams.map(s => s.id))
                        return root.outputStreams.filter(s => !onThisSink.has(s.id))
                    }

                    PwObjectTracker {
                        objects: [deviceSection.sink, ...deviceSection.streams].filter(n => n)
                    }

                    Column {
                        id: deviceColumn
                        anchors.left: parent.left
                        anchors.right: parent.right
                        spacing: 0

                        // Device header row (entire row is clickable)
                        Item {
                            width: parent.width
                            height: 36

                            Rectangle {
                                anchors.fill: parent
                                anchors.leftMargin: 2
                                anchors.rightMargin: 2
                                radius: 6
                                color: headerArea.containsMouse ? Theme.colors.hover : "transparent"

                                Behavior on color { ColorAnimation { duration: Theme.duration.fast } }
                            }

                            Row {
                                anchors.left: parent.left
                                anchors.leftMargin: 10
                                anchors.right: chevronIcon.left
                                anchors.rightMargin: 4
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 8

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: deviceSection.isDefault ? MaterialSymbols.speaker : MaterialSymbols.headphones
                                    color: deviceSection.isDefault ? Theme.colors.accent : Theme.colors.textMuted
                                    font.pixelSize: 16
                                    font.family: Theme.iconFont
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: deviceSection.sink.description || deviceSection.sink.name || "Unknown"
                                    color: Theme.colors.text
                                    font.pixelSize: 12
                                    font.weight: 500
                                    elide: Text.ElideRight
                                    width: Math.min(implicitWidth, deviceSection.width - 100)
                                }

                                Rectangle {
                                    visible: deviceSection.isDefault
                                    width: defText.width + 8
                                    height: 14
                                    radius: 3
                                    color: Qt.rgba(Theme.colors.accent.r, Theme.colors.accent.g, Theme.colors.accent.b, 0.12)
                                    anchors.verticalCenter: parent.verticalCenter

                                    Text {
                                        id: defText
                                        anchors.centerIn: parent
                                        text: "default"
                                        color: Theme.colors.accent
                                        font.pixelSize: 9
                                        font.weight: 600
                                    }
                                }
                            }

                            Text {
                                id: chevronIcon
                                anchors.right: parent.right
                                anchors.rightMargin: 12
                                anchors.verticalCenter: parent.verticalCenter
                                text: deviceSection.isExpanded ? MaterialSymbols.expandLess : MaterialSymbols.expandMore
                                color: deviceSection.isExpanded ? Theme.colors.accent : Theme.colors.textMuted
                                font.pixelSize: 18
                                font.family: Theme.iconFont

                                Behavior on color { ColorAnimation { duration: Theme.duration.fast } }
                            }

                            MouseArea {
                                id: headerArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.toggleExpanded(deviceSection.sink.id)
                            }
                        }

                        // Assigned streams (always visible)
                        Column {
                            width: parent.width
                            spacing: 0

                            Repeater {
                                model: deviceSection.streams

                                Item {
                                    id: streamItem
                                    required property var modelData
                                    width: parent.width
                                    height: 30

                                    readonly property var stream: modelData
                                    readonly property string appName: stream.description || stream.properties?.["application.name"] || stream.name || "Unknown"

                                    Rectangle {
                                        anchors.fill: parent
                                        anchors.leftMargin: 4
                                        anchors.rightMargin: 4
                                        radius: 6
                                        color: streamHover.containsMouse ? Theme.colors.hover : "transparent"

                                        Behavior on color { ColorAnimation { duration: Theme.duration.fast } }
                                    }

                                    Row {
                                        anchors.left: parent.left
                                        anchors.leftMargin: 34
                                        anchors.right: kickBtn.left
                                        anchors.rightMargin: 4
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 8

                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: streamItem.stream.audio?.muted ? MaterialSymbols.volumeOff : MaterialSymbols.volumeUp
                                            color: Theme.colors.textFaint
                                            font.pixelSize: 13
                                            font.family: Theme.iconFont
                                        }

                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: streamItem.appName
                                            color: Theme.colors.textSecondary
                                            font.pixelSize: 12
                                            elide: Text.ElideRight
                                            width: Math.min(implicitWidth, streamItem.width - 90)
                                        }
                                    }

                                    // Kick to default
                                    Item {
                                        id: kickBtn
                                        anchors.right: parent.right
                                        anchors.rightMargin: 8
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 20
                                        height: 20
                                        visible: !deviceSection.isDefault

                                        Text {
                                            anchors.centerIn: parent
                                            text: MaterialSymbols.close
                                            color: kickArea.containsMouse ? Theme.colors.textSecondary : Theme.colors.textFaint
                                            font.pixelSize: 14
                                            font.family: Theme.iconFont

                                            Behavior on color { ColorAnimation { duration: Theme.duration.fast } }
                                        }

                                        MouseArea {
                                            id: kickArea
                                            anchors.fill: parent
                                            anchors.margins: -4
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.kickStream(streamItem.stream)
                                        }
                                    }

                                    MouseArea {
                                        id: streamHover
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        acceptedButtons: Qt.NoButton
                                    }
                                }
                            }

                            // Empty state
                            Text {
                                visible: deviceSection.streams.length === 0
                                text: "No streams assigned"
                                color: Theme.colors.textFaint
                                font.pixelSize: 11
                                leftPadding: 34
                                topPadding: 2
                                bottomPadding: 2
                            }
                        }

                        // Inline stream picker (expanded)
                        Column {
                            width: parent.width
                            spacing: 0
                            visible: deviceSection.isExpanded
                            clip: true

                            Rectangle {
                                width: parent.width - 16
                                anchors.horizontalCenter: parent.horizontalCenter
                                height: 1
                                color: Theme.colors.separatorSubtle
                            }

                            Item {
                                width: parent.width
                                height: 24

                                Text {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 10
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "Assign stream"
                                    color: Theme.colors.textFaint
                                    font.pixelSize: 10
                                    font.weight: 500
                                }
                            }

                            Repeater {
                                model: deviceSection.assignableStreams

                                Item {
                                    id: pickerItem
                                    required property var modelData
                                    width: parent.width
                                    height: 30

                                    readonly property var stream: modelData
                                    readonly property string appName: stream.description || stream.properties?.["application.name"] || stream.name || "Unknown"

                                    Rectangle {
                                        anchors.fill: parent
                                        anchors.leftMargin: 4
                                        anchors.rightMargin: 4
                                        radius: 6
                                        color: pickerHover.containsMouse ? Theme.colors.hover : "transparent"

                                        Behavior on color { ColorAnimation { duration: Theme.duration.fast } }
                                    }

                                    Row {
                                        anchors.left: parent.left
                                        anchors.leftMargin: 34
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 8

                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: MaterialSymbols.volumeUp
                                            color: Theme.colors.textMuted
                                            font.pixelSize: 13
                                            font.family: Theme.iconFont
                                        }

                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: pickerItem.appName
                                            color: Theme.colors.accent
                                            font.pixelSize: 12
                                            font.weight: 500
                                            elide: Text.ElideRight
                                        }
                                    }

                                    MouseArea {
                                        id: pickerHover
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.assignStreamToSink(pickerItem.stream, deviceSection.sink)
                                    }
                                }
                            }

                            // No streams available
                            Text {
                                visible: deviceSection.assignableStreams.length === 0
                                text: "No available streams"
                                color: Theme.colors.textFaint
                                font.pixelSize: 11
                                leftPadding: 34
                                topPadding: 2
                                bottomPadding: 6
                            }

                            // Bottom padding
                            Item {
                                width: parent.width
                                height: 4
                                visible: deviceSection.assignableStreams.length > 0
                            }
                        }

                        // Bottom padding for card
                        Item {
                            width: parent.width
                            height: 4
                        }
                    }
                }
            }
        }

        // Empty state when no sinks
        Item {
            width: parent.width
            height: 60
            visible: root.sinks.length === 0

            Text {
                anchors.centerIn: parent
                text: "No audio devices"
                color: Theme.colors.textMuted
                font.pixelSize: 12
            }
        }
    }
}
