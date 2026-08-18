pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.UPower

Singleton {
    id: root

    readonly property var device: UPower.displayDevice

    // Desktops have no battery, and the indicator should disappear entirely rather
    // than sit at a meaningless 0%.
    readonly property bool available: (device?.isLaptopBattery ?? false) && (device?.isPresent ?? false)

    readonly property real percentage: device?.percentage ?? 0
    readonly property bool charging: device?.state === UPowerDeviceState.Charging || device?.state === UPowerDeviceState.FullyCharged
}
