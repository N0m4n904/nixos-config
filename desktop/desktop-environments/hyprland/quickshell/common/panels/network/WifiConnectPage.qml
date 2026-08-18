import QtQuick
import QtQuick.Controls
import qs.common.lib
import ".."

Column {
    id: root
    spacing: 0

    // Required properties
    required property var network
    required property bool connecting
    required property string connectionError

    signal back()
    signal connect(string password)

    // Check if network requires password
    // GUESSED: security field format
    readonly property bool requiresPassword: {
        const sec = root.network?.security ?? ""
        return sec !== "" && sec !== "--" && sec.toLowerCase() !== "open"
    }

    NetworkPageHeader {
        width: parent.width
        title: root.network?.ssid ?? "Connect"
        onBack: root.back()
    }

    // Network info
    Column {
        width: parent.width
        topPadding: 8
        spacing: 12

        // Signal strength indicator
        Row {
            spacing: 8

            Text {
                text: {
                    const signal = parseInt(root.network?.signal) || 0
                    if (signal >= 70) return MaterialSymbols.wifi
                    if (signal >= 40) return MaterialSymbols.wifi2Bar
                    return MaterialSymbols.wifi1Bar
                }
                color: Theme.colors.accent
                font.pixelSize: 24
                font.family: Theme.iconFont
            }

            Column {
                spacing: 2

                Text {
                    text: root.network?.ssid ?? ""
                    color: Theme.colors.text
                    font.pixelSize: 15
                    font.weight: 600
                }

                Row {
                    spacing: 6

                    Text {
                        text: root.network?.security ?? "Open"
                        color: Theme.colors.textMuted
                        font.pixelSize: 11
                    }

                    Text {
                        visible: !!Formatting.formatWifiBand(root.network?.freq)
                        text: "•"
                        color: Theme.colors.textFaint
                        font.pixelSize: 11
                    }

                    Text {
                        visible: !!Formatting.formatWifiBand(root.network?.freq)
                        text: Formatting.formatWifiBand(root.network?.freq)
                        color: Theme.colors.textMuted
                        font.pixelSize: 11
                    }

                    Text {
                        text: "•"
                        color: Theme.colors.textFaint
                        font.pixelSize: 11
                    }

                    Text {
                        text: (root.network?.signal ?? "0") + "% signal"
                        color: Theme.colors.textMuted
                        font.pixelSize: 11
                    }
                }
            }
        }

        // Separator
        Rectangle {
            width: parent.width
            height: 1
            color: Theme.colors.separatorSubtle
        }

        // Password field (if required)
        Column {
            width: parent.width
            spacing: 8
            visible: root.requiresPassword

            FieldLabel { text: "Password" }

            InputField {
                id: passwordField
                width: parent.width
                password: true
                placeholderText: "Enter password"
                onAccepted: {
                    if (text.length > 0) {
                        root.connect(text)
                    }
                }
            }
        }

        ErrorMessage {
            width: parent.width
            message: root.connectionError
        }

        // Connect button
        Item {
            width: parent.width
            height: 48

            ActionButton {
                anchors.centerIn: parent
                width: parent.width
                text: root.connecting ? "Connecting..." : "Connect"
                icon: root.connecting ? MaterialSymbols.wifi : ""
                loading: root.connecting
                enabled: !root.requiresPassword || passwordField.text.length >= 8
                onClicked: root.connect(passwordField.text)
            }
        }

        // Note about system password dialog
        Text {
            width: parent.width
            visible: root.requiresPassword
            text: "Note: If the connection fails, a system dialog may appear for authentication."
            color: Theme.colors.textFaint
            font.pixelSize: 10
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
        }
    }
}
