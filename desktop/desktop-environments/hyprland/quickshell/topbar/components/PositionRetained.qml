import QtQuick
import qs.common.lib

/*
 * PositionRetained
 *
 * An Item wrapper that ensures position changes trigger visual updates in
 * separate Wayland layer surfaces (e.g., PanelWindow).
 *
 * Problem:
 * When an Item's x/y position is changed via property binding inside a
 * PanelWindow (which is a separate Wayland layer surface), Qt's scene graph
 * doesn't automatically trigger a repaint. The property values update
 * correctly, but the visual representation remains stale until something
 * else forces a redraw (like mouse interaction).
 *
 * Root Cause:
 * Qt optimizes rendering by not redrawing surfaces that it believes haven't
 * changed visually. Since PanelWindow is a separate Wayland surface from the
 * main shell, Qt doesn't recognize that position changes in the binding
 * source (a different surface) should invalidate this surface's rendering.
 *
 * Solution:
 * Using Behavior on x/y forces Qt's animation system to process the position
 * change, which properly invalidates the scene graph and triggers a repaint.
 * With duration: 1, this is near-instantaneous - no visual animation occurs,
 * but the animation pipeline still runs, ensuring the repaint happens.
 *
 * Note: duration: 0 does NOT work - Qt appears to optimize away zero-duration
 * animations entirely, bypassing the animation pipeline. The minimum effective
 * duration is 1ms.
 *
 * Alternatives Explored:
 * - TransformWatcher: Correctly detects position changes and fires signals,
 *   but the binding updates alone don't trigger repaints
 * - Imperative assignment in signal handlers: Same issue - values update
 *   but no repaint
 * - anchors with margins instead of x/y: Same issue
 * - PopupAnchor: Only available on PopupWindow, not PanelWindow
 *
 * This pattern is also used by caelestia-shell for their bar popouts,
 * confirming it's the established approach in the Quickshell ecosystem.
 */
Item {
    id: root

    Behavior on x { NumberAnimation { duration: Theme.duration.instant } }
    Behavior on y { NumberAnimation { duration: Theme.duration.instant } }
}
