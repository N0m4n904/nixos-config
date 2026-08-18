pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Singleton {
    id: root

    readonly property var list: server.trackedNotifications?.values ?? []

    NotificationServer {
        id: server

        actionsSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        imageSupported: true

        // Notifications are transient toasts here, so nothing survives a shell reload.
        keepOnReload: false

        onNotification: notification => notification.tracked = true
    }
}
