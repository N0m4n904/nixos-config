import QtQuick
import QtQuick.Layouts
import qs.common.lib
import qs.common.data
import qs.common.widgets

// Mirrors the sensors pinned in the GNOME Vitals extension, in its order:
// CPU temperature, GPU temperature, memory usage, processor frequency, network
// down, network up.
RowLayout {
    spacing: Theme.metrics.sectionGap

    BarMetric {
        visible: Temperatures.cpu > 0
        icon: "thermostat"
        value: Format.celsius(Temperatures.cpu)
        tint: Temperatures.cpu >= 90 ? Theme.colors.red : Temperatures.cpu >= 80 ? Theme.colors.amber : Theme.colors.text
    }

    BarMetric {
        visible: Temperatures.gpu > 0
        icon: "mode_heat"
        value: Format.celsius(Temperatures.gpu)
        tint: Temperatures.gpu >= 100 ? Theme.colors.red : Temperatures.gpu >= 90 ? Theme.colors.amber : Theme.colors.text
    }

    BarMetric {
        icon: "memory_alt"
        value: Format.percent(Memory.usage)
    }

    BarMetric {
        icon: "speed"
        value: Format.gigahertz(Cpu.frequency)
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
