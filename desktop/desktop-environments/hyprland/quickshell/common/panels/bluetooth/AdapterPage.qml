import QtQuick
import qs.common.lib
import ".."

Column {
    id: root
    spacing: 0

    required property var adapters

    signal adapterClicked(var adapter)

    Text {
        text: "Bluetooth"
        color: Theme.colors.text
        font.pixelSize: 15
        font.weight: 600
        leftPadding: 4
        bottomPadding: 12
    }

    Repeater {
        model: root.adapters

        Column {
            width: root.width

            Rectangle {
                width: parent.width
                height: 1
                color: Theme.colors.separatorSubtle
                visible: index > 0
            }

            NavRow {
                width: parent.width
                icon: modelData.enabled ? MaterialSymbols.bluetooth : MaterialSymbols.bluetoothDisabled
                iconColor: modelData.enabled ? Theme.colors.accent : Theme.colors.textFaint
                label: modelData.name || modelData.adapterId || "Adapter"
                status: modelData.enabled ? "Enabled" : "Disabled"
                onClicked: root.adapterClicked(modelData)
            }
        }
    }

    Item {
        width: parent.width
        height: 60
        visible: root.adapters.length === 0

        Column {
            anchors.centerIn: parent
            spacing: 4

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: MaterialSymbols.bluetoothDisabled
                color: Theme.colors.textMuted
                font.pixelSize: 24
                font.family: Theme.iconFont
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "No Bluetooth adapters found"
                color: Theme.colors.textMuted
                font.pixelSize: 12
            }
        }
    }
}
