import QtQuick
import qs.common.lib
import qs.common.data
import qs.common.widgets

BarMetric {
    visible: Battery.available
    icon: Icons.battery(Battery.percentage * 100, Battery.charging)
    value: Format.percent(Battery.percentage)
    tint: Battery.charging ? Theme.colors.text : Battery.percentage <= 0.1 ? Theme.colors.red : Battery.percentage <= 0.3 ? Theme.colors.amber : Theme.colors.text
}
