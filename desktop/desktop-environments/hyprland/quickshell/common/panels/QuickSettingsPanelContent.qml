import QtQuick
import QtQuick.Layouts
import qs.common.lib
import "./quicksettings"

ColumnLayout {
	id: root
	spacing: 8

	property bool readOnly: false

	BrightnessSlider {
		Layout.fillWidth: true
		Layout.preferredHeight: 48
	}

	VolumeSlider {
		Layout.fillWidth: true
		Layout.preferredHeight: 48
	}
}
