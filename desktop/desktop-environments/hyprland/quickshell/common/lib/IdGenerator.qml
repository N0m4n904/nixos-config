pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property var _state: ({ counter: 0 })

    function nextId(): int {
        return _state.counter++
    }

    function nextUniqueId(): string {
        return `${Quickshell.processId}-${_state.counter++}`
    }
}
