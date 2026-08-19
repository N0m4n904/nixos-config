pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland

// The dock's model: pinned entries first, then anything running that is not pinned,
// which is how the GNOME dash orders itself.
Singleton {
    id: root

    readonly property var favouriteIds: (Quickshell.env("QS_DOCK_APPS") ?? "").split(":").filter(id => id !== "")

    readonly property var toplevels: Hyprland.toplevels?.values ?? []

    // The entry database populates asynchronously. Reading it inside the items binding
    // is what makes that binding re-run once it is ready - without the dependency the
    // list is built once while every lookup still returns null, and nothing recomputes
    // it, so the dock sits empty until something unrelated happens to change.
    readonly property var applications: DesktopEntries.applications?.values ?? []

    function entryFor(id) {
        return DesktopEntries.byId(id) ?? DesktopEntries.byId(id.replace(/\.desktop$/, "")) ?? DesktopEntries.heuristicLookup(id.replace(/\.desktop$/, ""));
    }

    function windowClass(toplevel) {
        const ipc = toplevel?.lastIpcObject ?? {};
        return ipc["class"] ?? ipc["initialClass"] ?? "";
    }

    // A window belongs to an entry when its class matches the entry's id or its
    // declared startup class. Matching is loose because clients are inconsistent about
    // which of the two they report - Zen answers "zen-beta" against zen-beta.desktop,
    // while others report a reverse-DNS class.
    function belongsTo(toplevel, entry) {
        if (!entry)
            return false;

        const cls = windowClass(toplevel).toLowerCase();
        if (cls === "")
            return false;

        const candidates = [entry.id ?? "", entry.startupClass ?? "", entry.name ?? ""].map(value => value.replace(/\.desktop$/, "").toLowerCase()).filter(value => value !== "");

        return candidates.some(value => value === cls || cls.endsWith("." + value) || value.endsWith("." + cls));
    }

    function windowsFor(entry) {
        return toplevels.filter(toplevel => belongsTo(toplevel, entry));
    }

    // The set of tiles, rebuilt only when it can actually differ. Binding this to the
    // toplevels directly would hand the dock a fresh array on every window event, and
    // a Repeater discards and recreates every delegate when its model changes - which
    // reloads each icon and resets anything the tiles were showing. The per-tile
    // running state does not need that: it is bound separately and updates in place.
    property var items: []

    // Changes only when a tile could appear or disappear: the pinned list, whether the
    // entry database has loaded, or which application classes currently have a window.
    readonly property string signature: {
        const classes = [];
        for (const toplevel of toplevels) {
            const cls = windowClass(toplevel).toLowerCase();
            if (cls !== "" && !classes.includes(cls))
                classes.push(cls);
        }

        return `${favouriteIds.join("|")}::${applications.length > 0}::${classes.sort().join(",")}`;
    }

    onSignatureChanged: rebuild()
    Component.onCompleted: rebuild()

    function rebuild() {
        // With no entries loaded every lookup returns null, which would empty the dock.
        if (applications.length === 0) {
            items = [];
            return;
        }

        const pinned = favouriteIds.map(id => ({
                    id: id,
                    entry: entryFor(id),
                    pinned: true
                })).filter(item => item.entry);

        // Running windows whose entry is not already pinned, one tile per application
        // rather than per window.
        const seen = pinned.map(item => item.entry);
        const extra = [];

        for (const toplevel of toplevels) {
            const cls = windowClass(toplevel);
            if (cls === "")
                continue;

            const entry = DesktopEntries.heuristicLookup(cls);
            if (!entry || seen.includes(entry) || extra.some(item => item.entry === entry))
                continue;

            extra.push({
                id: cls,
                entry: entry,
                pinned: false
            });
        }

        items = pinned.concat(extra);
    }

    // GNOME's click-action is cycle-windows: launch when nothing is open, focus when
    // one window is, and step through them when several are.
    function activate(entry) {
        const windows = windowsFor(entry);

        if (windows.length === 0) {
            entry.execute();
            return;
        }

        const active = Hyprland.activeToplevel;
        const current = windows.findIndex(toplevel => toplevel === active);
        const next = windows[(current + 1) % windows.length];

        if (next?.address)
            Hyprland.dispatch(`focuswindow address:0x${next.address}`);
    }
}
