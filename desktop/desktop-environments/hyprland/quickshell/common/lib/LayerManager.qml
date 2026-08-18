pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

Singleton {
    id: root

    // Track applied rules: namespace -> options
    property var _applied: ({})
    // Pending rules to apply: [{ namespace, options }]
    property var _pending: []

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "configreloaded") {
                root._reapplyAll()
            }
        }
    }

    function _reapplyAll(): void {
        console.log("[LayerManager] configreloaded — re-applying all rules")
        for (const namespace in _applied) {
            _pending.push({ namespace, options: _applied[namespace] })
        }
        _scheduleFlush()
    }

    function obtainLease(namespace: string, options: var): var {
        console.log("[LayerManager] obtainLease:", namespace, JSON.stringify(options))
        if (!_applied[namespace]) {
            _applied[namespace] = options
            _pending.push({ namespace, options })
            _scheduleFlush()
        }

        return {
            namespace: namespace,
            release: function() {
                delete root._applied[namespace]
            }
        }
    }

    property bool _flushScheduled: false
    function _scheduleFlush(): void {
        if (!_flushScheduled) {
            _flushScheduled = true
            Qt.callLater(_flush)
        }
    }

    // Queue of hyprctl command arrays to execute one by one
    property var _cmdQueue: []

    function _flush(): void {
        _flushScheduled = false
        if (_pending.length === 0) return

        console.log("[LayerManager] flushing", _pending.length, "leases")

        for (const { namespace, options } of _pending) {
            const ruleName = namespace.replace("quickshell:", "qs-")

            _cmdQueue.push(["hyprctl", "keyword", `layerrule[${ruleName}]:match:namespace`, namespace])

            if (options.blur) {
                _cmdQueue.push(["hyprctl", "keyword", `layerrule[${ruleName}]:blur`, "on"])
                _cmdQueue.push(["hyprctl", "keyword", `layerrule[${ruleName}]:ignore_alpha`, String(options.ignoreAlpha ?? 0)])
            }
            if (options.order !== undefined) {
                _cmdQueue.push(["hyprctl", "keyword", `layerrule[${ruleName}]:order`, String(options.order)])
            }
            if (options.animation) {
                _cmdQueue.push(["hyprctl", "keyword", `layerrule[${ruleName}]:animation`, options.animation])
            }
        }
        _pending = []

        console.log("[LayerManager] queued", _cmdQueue.length, "hyprctl commands")
        if (!_applyProc.running) {
            _processNext()
        }
    }

    function _processNext(): void {
        if (_cmdQueue.length === 0) {
            console.log("[LayerManager] all commands applied")
            return
        }
        const cmd = _cmdQueue.shift()
        console.log("[LayerManager] exec:", cmd.join(" "))
        _applyProc.command = cmd
        _applyProc.running = true
    }

    Process {
        id: _applyProc
        running: false
        stdout: SplitParser {
            onRead: data => console.log("[LayerManager] stdout:", data)
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) console.warn("[LayerManager] FAILED exit:", exitCode, exitStatus)
            root._processNext()
        }
    }
}
