import QtQuick
import Quickshell
import Quickshell.Hyprland

// Keeps newly mapped windows out from under the bar.
//
// Hyprland accepts a client's requested position whenever the window's *centre point*
// falls inside the work area, so an application restoring a tall window at y=0 is
// honoured even though its top edge - and with it the title bar it is dragged by -
// ends up behind the bar. The check is on the centre, not the box, and no window rule
// clamps a window into the work area, so this is done here instead of maintaining a
// list of the applications that happen to do it.
Scope {
    id: root

    // Addresses already nudged. A window is corrected once, as it appears; moving it
    // back under the bar afterwards is a deliberate act and is left alone.
    property var corrected: ({})

    function reservedTop(toplevel) {
        const monitor = toplevel?.monitor;
        if (!monitor)
            return null;

        // reserved is [left, top, right, bottom] in the monitor's own coordinates.
        const reserved = monitor.lastIpcObject?.reserved;
        if (!reserved || reserved.length < 2)
            return null;

        return monitor.y + reserved[1];
    }

    function clamp(toplevel) {
        const address = toplevel?.address;
        if (!address || corrected[address])
            return;

        const geometry = toplevel.lastIpcObject;
        const at = geometry?.at;
        if (!at || at.length < 2)
            return;

        const minimumY = reservedTop(toplevel);
        if (minimumY === null || at[1] >= minimumY)
            return;

        corrected[address] = true;
        Hyprland.dispatch(`movewindowpixel exact ${at[0]} ${minimumY},address:0x${address}`);
    }

    function review() {
        for (const toplevel of Hyprland.toplevels.values)
            clamp(toplevel);
    }

    // A toplevel can appear before Hyprland has settled its geometry, in which case
    // there is nothing to measure yet. Checking again shortly after covers that
    // without polling, since nothing corrects a window twice.
    Timer {
        id: settle

        interval: 300
        repeat: false
        onTriggered: root.review()
    }

    Connections {
        target: Hyprland.toplevels

        function onValuesChanged() {
            root.review();
            settle.restart();
        }
    }
}
