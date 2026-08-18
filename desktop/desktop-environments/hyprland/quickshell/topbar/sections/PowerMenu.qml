import QtQuick
import QtQuick.Layouts
import qs.common.lib
import qs.common.widgets

RowLayout {
    id: root

    property bool expanded: false

    spacing: Theme.metrics.gap

    Reveal {
        Layout.alignment: Qt.AlignVCenter
        revealed: root.expanded

        BarButton {
            Layout.alignment: Qt.AlignVCenter
            icon: "lock"
            tint: Theme.colors.blue
            onClicked: {
                root.expanded = false;
                Commands.run(Commands.lock);
            }
        }

        BarButton {
            Layout.alignment: Qt.AlignVCenter
            icon: "rotate_left"
            tint: Theme.colors.green
            onClicked: {
                root.expanded = false;
                Commands.run(Commands.reboot);
            }
        }

        BarButton {
            Layout.alignment: Qt.AlignVCenter
            icon: "logout"
            tint: Theme.colors.amber
            onClicked: {
                root.expanded = false;
                Commands.run(Commands.logout);
            }
        }

        BarButton {
            Layout.alignment: Qt.AlignVCenter
            icon: "power_off"
            tint: Theme.colors.red
            onClicked: {
                root.expanded = false;
                Commands.run(Commands.poweroff);
            }
        }
    }

    BarButton {
        Layout.alignment: Qt.AlignVCenter
        icon: "power_settings_new"
        onClicked: root.expanded = !root.expanded
    }
}
