pragma Singleton

import QtQuick

QtObject {
    function percent(fraction) {
        return Math.round(fraction * 100) + "%";
    }

    function celsius(degrees) {
        return Math.round(degrees) + "°C";
    }

    function rate(bytesPerSecond) {
        const megabytes = bytesPerSecond / 1e6;
        if (megabytes >= 1)
            return megabytes.toFixed(1) + " MB/s";
        return Math.round(bytesPerSecond / 1e3) + " KB/s";
    }
}
