import QtQuick
import QtQuick.Effects
import "../lib"

Item {
	id: root

	required property QtObject panel
	required property int index
	required property var panels
	required property var dp

	required property real screenWidth
	required property real topOffset
	required property real edgeMargin
	required property real panelGap

	property var contentItem: null
	readonly property real contentHeight: contentItem?.implicitHeight ?? 200
	readonly property real panelHeight: contentHeight + 24
	readonly property real panelWidth: panel.panelWidth

	// Calculate offset from right edge (sum of visible panels to our right = higher index)
	readonly property real rightOffset: {
		let offset = 0
		for (let i = index + 1; i < panels.length; i++) {
			const p = panels[i]
			if (p && p.show) {
				offset += p.panelWidth + panelGap
			}
		}
		return offset
	}

	// Hidden position: behind the rightmost visible panel (or edge if none)
	// Returns far off-screen if screenWidth not yet valid to prevent animation on load
	readonly property real panelXHidden: {
		if (screenWidth <= 0) return 10000

		for (let i = panels.length - 1; i > index; i--) {
			const p = panels[i]
			if (p && p.show) {
				let offset = 0
				for (let j = i + 1; j < panels.length; j++) {
					if (panels[j]?.show) {
						offset += panels[j].panelWidth + panelGap
					}
				}
				return screenWidth - edgeMargin - offset - p.panelWidth
			}
		}
		return screenWidth - edgeMargin
	}

	readonly property real panelXVisible: screenWidth - edgeMargin - rightOffset - panel.panelWidth
	readonly property real panelXTarget: panel.show ? panelXVisible : panelXHidden

	// Track if panel is currently in closing animation
	property bool isClosing: false
	// Track current X for visibility (panel visible while animating out)
	property real currentPanelX: panelXHidden
	// Panel visible if: showing, or currently closing
	readonly property bool panelVisible: screenWidth > 0 && (panel.show || isClosing)

	Connections {
		target: panel
		function onShowChanged() {
			if (!panel.show && currentPanelX < panelXHidden - 1) {
				root.isClosing = true
			}
		}
	}

	onCurrentPanelXChanged: {
		if (isClosing && currentPanelX >= panelXHidden - 1) {
			isClosing = false
		}
	}

	// Content component to be loaded
	readonly property Component contentComponent: panel.content

	// Signal when close is requested
	signal closeRequested()

	function bindContentItem(item) {
		contentItem = item
	}

	function handleContentLoaded(item) {
		if (item && typeof item.closeRequested !== "undefined") {
			item.closeRequested.connect(closeRequested)
		}
	}
}
