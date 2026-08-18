pragma Singleton

import QtQuick

// Decimal places follow the GNOME Vitals extension with use-higher-precision set, so
// the bar and the extension read the same rather than one looking coarser.
QtObject {
    function percent(fraction) {
        return (fraction * 100).toFixed(1) + "%";
    }

    function celsius(degrees) {
        return degrees.toFixed(1) + "°C";
    }

    function gigahertz(value) {
        return value.toFixed(2) + " GHz";
    }

    function rate(bytesPerSecond) {
        const megabytes = bytesPerSecond / 1e6;
        if (megabytes >= 1)
            return megabytes.toFixed(1) + " MB/s";
        return (bytesPerSecond / 1e3).toFixed(1) + " KB/s";
    }
}
