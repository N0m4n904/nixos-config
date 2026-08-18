pragma Singleton
import QtQuick

QtObject {
    // Navigation
    readonly property string expandMore: "expand_more"
    readonly property string expandLess: "expand_less"
    readonly property string chevronRight: "chevron_right"
    readonly property string chevronLeft: "chevron_left"
    readonly property string arrowBack: "arrow_back"
    readonly property string check: "check"
    readonly property string close: "close"
    readonly property string moreHoriz: "more_horiz"
    readonly property string refresh: "refresh"

    // Power
    readonly property string power: "power_settings_new"
    readonly property string restart: "restart_alt"
    readonly property string logout: "logout"

    // Audio
    readonly property string volumeUp: "volume_up"
    readonly property string volumeDown: "volume_down"
    readonly property string volumeMute: "volume_mute"
    readonly property string volumeOff: "volume_off"
    readonly property string mic: "mic"
    readonly property string micOff: "mic_off"

    // Brightness
    readonly property string brightnessLow: "brightness_low"
    readonly property string brightnessMedium: "brightness_medium"
    readonly property string brightnessHigh: "brightness_high"

    // Media playback
    readonly property string playArrow: "play_arrow"
    readonly property string pause: "pause"
    readonly property string skipNext: "skip_next"
    readonly property string skipPrevious: "skip_previous"
    readonly property string repeat: "repeat"
    readonly property string repeatOn: "repeat_on"
    readonly property string repeatOneOn: "repeat_one_on"
    readonly property string shuffle: "shuffle"
    readonly property string shuffleOn: "shuffle_on"

    // Status indicators
    readonly property string emergencyHeat: "emergency_heat_2"
    readonly property string runningWithErrors: "running_with_errors"
    readonly property string compress: "compress"
    readonly property string dangerous: "dangerous"
    readonly property string discFull: "disc_full"
    readonly property string speed: "speed"

    // Network
    readonly property string primaryRoute: "editor_choice"
    readonly property string route: "route"
    readonly property string signalDisconnected: "signal_disconnected"
    readonly property string networkPing: "network_ping"
    readonly property string wifi: "wifi"
    readonly property string wifi2Bar: "network_wifi_2_bar"
    readonly property string wifi1Bar: "network_wifi_1_bar"
    readonly property string wifiOff: "wifi_off"
    readonly property string ethernet: "lan"
    readonly property string ethernetOff: "public_off"
    readonly property string networkOnline: "public"
    readonly property string simCard: "sim_card"
    readonly property string signalCellular: "signal_cellular_alt"
    readonly property string signalCellularOff: "signal_cellular_off"

    // Battery
    readonly property string batteryFull: "battery_full"
    readonly property string battery6Bar: "battery_6_bar"
    readonly property string battery5Bar: "battery_5_bar"
    readonly property string battery4Bar: "battery_4_bar"
    readonly property string battery3Bar: "battery_3_bar"
    readonly property string battery2Bar: "battery_2_bar"
    readonly property string battery1Bar: "battery_1_bar"
    readonly property string battery0Bar: "battery_0_bar"
    readonly property string batteryCharging: "battery_charging_full"
    readonly property string batteryAlert: "battery_alert"

    // Caffeine
    readonly property string caffeineOff: "local_cafe"
    readonly property string caffeineOn: "emoji_food_beverage"

    // Bluetooth
    readonly property string bluetooth: "bluetooth"
    readonly property string bluetoothConnected: "bluetooth_connected"
    readonly property string bluetoothDisabled: "bluetooth_disabled"
    readonly property string bluetoothSearching: "bluetooth_searching"
    readonly property string headphones: "headphones"
    readonly property string keyboard: "keyboard_alt"
    readonly property string mouse: "mouse"
    readonly property string speaker: "speaker"
    readonly property string phoneAndroid: "phone_android"
    readonly property string computer: "computer"
    readonly property string gamepad: "sports_esports"
    readonly property string watch: "watch"
    readonly property string link: "link"

    // Input
    readonly property string visibility: "visibility"
    readonly property string visibilityOff: "visibility_off"

    // Audio routing
    readonly property string tune: "tune"

    // Misc
    readonly property string cadence: "cadence"

    // Authentication
    readonly property string fingerprint: "fingerprint"
}
