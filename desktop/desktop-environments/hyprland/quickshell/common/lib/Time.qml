pragma Singleton

import QtQuick
import Quickshell

Singleton {
    readonly property string clock: Qt.formatDateTime(systemClock.date, "HH:mm:ss")
    readonly property string date: Qt.formatDateTime(systemClock.date, "ddd, d MMM")

    SystemClock {
        id: systemClock
        precision: SystemClock.Seconds
    }
}
