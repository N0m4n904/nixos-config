import QtQuick
import Quickshell
import Quickshell.Hyprland

// Keeps windows out from under the bar, permanently.
//
// Hyprland accepts a client's requested position whenever the window's *centre point*
// falls inside the work area, so an application restoring a tall window at y=0 is
// honoured even though its top edge - and the title bar it is dragged by - ends up
// behind the bar. The check is on the centre, not the box, and no window rule clamps a
// window into the work area.
//
// Correcting a window as it appears is not sufficient: Electron applications re-apply
// their saved bounds after mapping, sometimes seconds later, and VSCodium does it late
// enough to defeat any reasonable settling period. So this does not try to guess when a
// window has finished moving itself - it simply keeps checking, and puts back anything
// that ends up under the bar.
Scope {
    id: root

    readonly property int sweepMs: 400

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

    function clamp(toplevel) {
        const address = toplevel?.address;
        if (!address)
            return;

        const at = toplevel.lastIpcObject?.at;
        const minimumY = reservedTop(toplevel);

        if (!at || at.length < 2 || minimumY === null || at[1] >= minimumY)
            return;

        Hyprland.dispatch(`movewindowpixel exact ${at[0]} ${minimumY},address:0x${address}`);
    }

    function review() {
        for (const toplevel of Hyprland.toplevels?.values ?? [])
            clamp(toplevel);
    }

    Component.onCompleted: Hyprland.refreshToplevels()

    // Runs for the life of the session. It walks a handful of windows and dispatches
    // only when one is actually out of place, which costs nothing measurable, and it is
    // the only thing that survives an application moving itself back at an arbitrary
    // moment.
    Timer {
        interval: root.sweepMs
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.review()
    }

    // The model is empty at startup and fills asynchronously, so this catches each
    // window as it is announced rather than waiting for the next sweep.
    Connections {
        target: Hyprland.toplevels

        function onValuesChanged() {
            root.review();
        }
    }
}
