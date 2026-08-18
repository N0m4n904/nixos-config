pragma Singleton

import QtQuick

QtObject {
    readonly property var batteryBars: [
        {
            atLeast: 100,
            name: "battery_full"
        },
        {
            atLeast: 90,
            name: "battery_6_bar"
        },
        {
            atLeast: 75,
            name: "battery_5_bar"
        },
        {
            atLeast: 60,
            name: "battery_4_bar"
        },
        {
            atLeast: 45,
            name: "battery_3_bar"
        },
        {
            atLeast: 30,
            name: "battery_2_bar"
        },
        {
            atLeast: 10,
            name: "battery_1_bar"
        }
    ]

    function battery(percentage, charging) {
        if (charging)
            return "battery_charging_90";
        const step = batteryBars.find(bar => percentage >= bar.atLeast);
        return step ? step.name : "battery_0_bar";
    }

    function volume(level, muted) {
        if (muted)
            return "volume_off";
        if (level <= 0)
            return "volume_mute";
        return level >= 0.5 ? "volume_up" : "volume_down";
    }

    function playback(playing) {
        return playing ? "pause" : "play_arrow";
    }

    function loop(state) {
        switch (state) {
        case "track":
            return "repeat_one_on";
        case "playlist":
            return "repeat_on";
        default:
            return "repeat";
        }
    }
}
