import QtQuick
import QtQuick.Layouts
import qs.common.lib
import qs.common.data
import qs.common.widgets

RowLayout {
    spacing: Theme.metrics.sectionGap

    BarMetric {
        icon: "memory"
        value: Format.percent(Cpu.usage)
    }

    BarMetric {
        icon: "memory_alt"
        value: Format.percent(Memory.usage)
    }

    BarMetric {
        visible: Temperatures.cpu > 0
        icon: "thermostat"
        value: Format.celsius(Temperatures.cpu)
        tint: Temperatures.cpu >= 90 ? Theme.colors.red : Temperatures.cpu >= 80 ? Theme.colors.amber : Theme.colors.text
    }

    BarMetric {
        visible: Temperatures.gpu > 0
        icon: "thermostat"
        value: Format.celsius(Temperatures.gpu)
        tint: Temperatures.gpu >= 100 ? Theme.colors.red : Temperatures.gpu >= 90 ? Theme.colors.amber : Theme.colors.text
    }

    BarMetric {
        icon: "download"
        value: Format.rate(Network.downstream)
    }

    BarMetric {
        icon: "upload"
        value: Format.rate(Network.upstream)
    }
}
