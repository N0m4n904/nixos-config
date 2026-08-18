pragma Singleton
import QtQuick

QtObject {
    function formatBytes(bytes) {
        if (bytes < 0) return "-"
        if (bytes < 1024) return bytes.toFixed(0) + " B"
        if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(0) + " KiB"
        if (bytes < 1024 * 1024 * 1024) return (bytes / 1024 / 1024).toFixed(1) + " MiB"
        return (bytes / 1024 / 1024 / 1024).toFixed(1) + " GiB"
    }

    function formatBytesCompact(bytes) {
        if (bytes < 0) return "-"
        if (bytes < 1024) return bytes.toFixed(0) + "B"
        if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(0) + "K"
        if (bytes < 1024 * 1024 * 1024) return (bytes / 1024 / 1024).toFixed(1) + "M"
        return (bytes / 1024 / 1024 / 1024).toFixed(1) + "G"
    }

    function formatBytesPerSecond(bytes) {
        if (bytes < 0) return "-"
        if (bytes < 1000) return bytes.toFixed(0) + " B/s"
        const kb = bytes / 1000
        if (bytes < 1000 * 1000) return (kb < 10 ? kb.toFixed(1) : kb.toFixed(0)) + " KB/s"
        const mb = bytes / 1000 / 1000
        if (bytes < 1000 * 1000 * 1000) return (mb < 10 ? mb.toFixed(1) : mb.toFixed(0)) + " MB/s"
        const gb = bytes / 1000 / 1000 / 1000
        return (gb < 10 ? gb.toFixed(1) : gb.toFixed(0)) + " GB/s"
    }

    function formatUptime(seconds) {
        const d = Math.floor(seconds / 86400)
        const h = Math.floor((seconds % 86400) / 3600)
        const m = Math.floor((seconds % 3600) / 60)
        if (d > 0) return d + "d " + h + "h"
        if (h > 0) return h + "h " + m + "m"
        return m + "m"
    }

    function formatCount(n) {
        if (n < 1000) return Math.round(n).toString()
        if (n < 10000) return (n / 1000).toFixed(1) + "k"
        if (n < 1000000) return Math.round(n / 1000) + "k"
        return (n / 1000000).toFixed(2) + "M"
    }

    function formatFrequency(hz) {
        if (hz < 0) return "-"
        if (hz < 10000) return Math.round(hz) + " Hz"
        const khz = hz / 1000
        if (hz < 10000000) {
            if (khz < 100) return khz.toFixed(1) + " kHz"
            return Math.round(khz) + " kHz"
        }
        const mhz = hz / 1000000
        if (hz < 1000000000) {
            if (mhz < 100) return mhz.toFixed(1) + " MHz"
            return Math.round(mhz) + " MHz"
        }
        const ghz = hz / 1000000000
        if (hz < 1000000000000) {
            if (ghz < 10) return ghz.toFixed(2) + " GHz"
            if (ghz < 100) return ghz.toFixed(1) + " GHz"
            return Math.round(ghz) + " GHz"
        }
        const thz = hz / 1000000000000
        if (thz < 10) return thz.toFixed(2) + " THz"
        return thz.toFixed(1) + " THz"
    }

    function formatWithUnit(value, unit) {
        if (value < 0) return "-"
        if (value < 1) return value.toFixed(2) + " " + unit
        if (value < 10) return value.toFixed(1) + " " + unit
        if (value < 1000) return Math.round(value) + " " + unit
        const k = value / 1000
        if (k < 10) return k.toFixed(1) + " k" + unit
        if (k < 1000) return Math.round(k) + " k" + unit
        const m = value / 1000000
        if (m < 10) return m.toFixed(1) + " M" + unit
        if (m < 1000) return Math.round(m) + " M" + unit
        const g = value / 1000000000
        if (g < 10) return g.toFixed(1) + " G" + unit
        return Math.round(g) + " G" + unit
    }

    function formatLinkSpeed(mbps) {
        if (mbps <= 0) return ""
        if (mbps >= 1000) return (mbps / 1000) + " Gbps"
        return mbps + " Mbps"
    }

    function formatWifiBand(freq) {
        if (!freq) return ""
        const freqNum = typeof freq === "string" ? parseInt(freq) : freq
        if (freqNum >= 2400 && freqNum < 2500) return "2.4 GHz"
        if (freqNum >= 5150 && freqNum < 5900) return "5 GHz"
        if (freqNum >= 5925 && freqNum < 7125) return "6 GHz"
        return ""
    }

    function formatWifiGeneration(freq, rate) {
        if (!freq || !rate) return ""
        const freqNum = typeof freq === "string" ? parseInt(freq) : freq
        const rateNum = typeof rate === "string" ? parseInt(rate) : rate

        if (freqNum >= 5925) {
            return rateNum > 2000 ? "WiFi 7 (802.11be)" : "WiFi 6E (802.11ax)"
        }
        if (freqNum >= 5000) {
            if (rateNum > 1000) return "WiFi 6 (802.11ax)"
            if (rateNum > 400) return "WiFi 5 (802.11ac)"
            return "WiFi 4 (802.11n)"
        }
        if (rateNum > 400) return "WiFi 6 (802.11ax)"
        if (rateNum > 54) return "WiFi 4 (802.11n)"
        return "WiFi 4 (802.11g)"
    }

    function formatBluetoothDeviceIcon(iconName) {
        if (!iconName) return "bluetooth"
        if (iconName.includes("headphone") || iconName.includes("headset") || iconName.includes("audio"))
            return "headphones"
        if (iconName.includes("keyboard")) return "keyboard_alt"
        if (iconName.includes("mouse") || iconName.includes("input-mouse")) return "mouse"
        if (iconName.includes("speaker")) return "speaker"
        if (iconName.includes("phone")) return "phone_android"
        if (iconName.includes("computer")) return "computer"
        if (iconName.includes("game") || iconName.includes("joystick")) return "sports_esports"
        if (iconName.includes("watch")) return "watch"
        return "bluetooth"
    }

    function truncateTitle(text, maxWidth, fontMetrics) {
        if (!text || maxWidth <= 0) return text || ""

        function fits(s) {
            const w = fontMetrics.advanceWidth(s.trim())
            console.log("fits check:", s.trim(), "width:", w, "maxWidth:", maxWidth, "fits:", w <= maxWidth)
            return w <= maxWidth
        }

        function centerEllipsis(s) {
            s = s.trim()
            if (fits(s)) return s
            if (s.length <= 3) return s  // Ellipsis only worth it if removing 3+ chars

            let left = 0
            let right = s.length - 1
            while (right - left > 1) {
                const candidate = s.substring(0, left + 1) + "…" + s.substring(right)
                // Only use ellipsis if we're removing at least 3 characters
                const charsRemoved = s.length - (left + 1) - (s.length - right)
                if (charsRemoved < 3) {
                    return s  // Not worth truncating
                }
                if (fits(candidate)) {
                    left++
                } else {
                    right--
                }
            }
            // Final check: only return ellipsis version if removing 3+ chars
            const finalRemoved = s.length - (left + 1) - (s.length - right)
            if (finalRemoved < 3) return s
            return s.substring(0, left + 1) + "…" + s.substring(right)
        }

        if (fits(text)) {
            console.log("FINAL: text fits as-is, returning:", text)
            return text
        }

        let current = text

        // Iteratively remove bracket groups and dash segments
        while (true) {
            // 2a: Find last closing bracket
            const lastParen = current.lastIndexOf(')')
            const lastBracket = current.lastIndexOf(']')
            const lastClose = Math.max(lastParen, lastBracket)

            if (lastClose > 0) {
                // Trim to include the bracket
                const trimmed = current.substring(0, lastClose + 1)
                if (fits(trimmed)) {
                    const result = trimmed.trim()
                    console.log("FINAL: trim to bracket, returning:", result, "width:", fontMetrics.advanceWidth(result))
                    return result
                }

                // 2b: Find corresponding opening bracket
                const openChar = current[lastClose] === ')' ? '(' : '['
                const lastOpen = current.lastIndexOf(openChar, lastClose - 1)

                if (lastOpen > 0) {
                    // Trim before the opening bracket
                    current = current.substring(0, lastOpen)
                    if (fits(current)) {
                        const result = current.trim()
                        console.log("FINAL: trim before bracket, returning:", result, "width:", fontMetrics.advanceWidth(result))
                        return result
                    }
                    continue
                }
            }

            // 2d: No more brackets, try dashes
            const lastDash = current.lastIndexOf(' - ')
            if (lastDash > 0) {
                current = current.substring(0, lastDash)
                if (fits(current)) {
                    const result = current.trim()
                    console.log("FINAL: trim at dash, returning:", result, "width:", fontMetrics.advanceWidth(result))
                    return result
                }
                continue
            }

            // 2f: No more structure to remove, use center ellipsis
            const result = centerEllipsis(current)
            console.log("FINAL: center ellipsis, returning:", result, "width:", fontMetrics.advanceWidth(result))
            return result
        }
    }
}
