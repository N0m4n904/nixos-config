pragma Singleton

import QtQuick
import Quickshell

// Every command the bar can trigger is injected by the Nix module rather than looked
// up on PATH, so the shell never depends on what happens to be in the session
// environment and a missing tool is a build error instead of a dead button.
QtObject {
    readonly property string clipboard: Quickshell.env("QS_CLIPBOARD_COMMAND") ?? ""
    readonly property string launcher: Quickshell.env("QS_LAUNCHER_COMMAND") ?? ""
    readonly property string lock: Quickshell.env("QS_LOCK_COMMAND") ?? ""
    readonly property string logout: Quickshell.env("QS_LOGOUT_COMMAND") ?? ""
    readonly property string reboot: Quickshell.env("QS_REBOOT_COMMAND") ?? ""
    readonly property string poweroff: Quickshell.env("QS_POWEROFF_COMMAND") ?? ""

    function run(command) {
        if (command)
            Quickshell.execDetached(["sh", "-c", command]);
    }
}
