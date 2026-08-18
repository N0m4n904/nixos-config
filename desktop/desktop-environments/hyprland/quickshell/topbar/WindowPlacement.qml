import QtQuick
import Quickshell
import Quickshell.Hyprland

// Keeps newly mapped windows out from under the bar.
//
// Hyprland accepts a client's requested position whenever the window's *centre point*
// falls inside the work area, so an application restoring a tall window at y=0 is
// honoured even though its top edge - and with it the title bar it is dragged by -
// ends up behind the bar. The check is on the centre, not the box, and no window rule
// clamps a window into the work area, so it is done here rather than by maintaining a
// list of the applications that happen to do it.
Scope {
    id: root

    // A window is watched for a short while after it is first seen, not corrected once.
    // Electron applications map first and apply their saved bounds a moment later, so a
    // single correction is simply undone. After the window settles it is left alone,
    // and moving it under the bar yourself is then a deliberate act.
    readonly property int graceMs: 4000
    readonly property int sweepMs: 250

    property var firstSeen: ({})

    function reservedTop(toplevel) {
        const monitor = toplevel?.monitor;
        if (!monitor)
            return null;

        // reserved is [left, top, right, bottom], in the monitor's own coordinates.
        const reserved = monitor.lastIpcObject?.reserved;
        if (!reserved || reserved.length < 2)
            return null;

        return monitor.y + reserved[1];
    }

    // True while this window is still within its grace period, so the sweep knows
    // whether there is anything left to watch.
    function clamp(toplevel, now) {
        const address = toplevel?.address;
        if (!address)
            return false;

        if (firstSeen[address] === undefined)
            firstSeen[address] = now;

        if (now - firstSeen[address] > graceMs)
            return false;

        const at = toplevel.lastIpcObject?.at;
        const minimumY = reservedTop(toplevel);

        if (at && at.length >= 2 && minimumY !== null && at[1] < minimumY)
            Hyprland.dispatch(`movewindowpixel exact ${at[0]} ${minimumY},address:0x${address}`);

        return true;
    }

    function review() {
        const now = Date.now();
        const toplevels = Hyprland.toplevels?.values ?? [];
        let watching = false;

        for (const toplevel of toplevels) {
            if (clamp(toplevel, now))
                watching = true;
        }

        // Forget windows that have gone, so the record cannot grow for a session.
        const live = {};
        for (const toplevel of toplevels) {
            if (toplevel.address && firstSeen[toplevel.address] !== undefined)
                live[toplevel.address] = firstSeen[toplevel.address];
        }
        firstSeen = live;

        sweep.running = watching;
    }

    Component.onCompleted: Hyprland.refreshToplevels()

    // Runs only while something is still within its grace period. The model is empty
    // when this component is created and fills asynchronously, so there is nothing to
    // do here beyond waiting for the first window to arrive.
    Timer {
        id: sweep

        interval: root.sweepMs
        repeat: true
        running: false
        onTriggered: root.review()
    }

    Connections {
        target: Hyprland.toplevels

        function onValuesChanged() {
            root.review();
            sweep.running = true;
        }
    }
}
