pragma Singleton

import QtQuick
import Quickshell

Singleton {
    // OKLCH to sRGB
    function oklch(hue, C, L) {
        const H = hue * Math.PI / 180
        const a = C * Math.cos(H), b = C * Math.sin(H)
        const l_ = L + 0.3963377774 * a + 0.2158037573 * b
        const m_ = L - 0.1055613458 * a - 0.0638541728 * b
        const s_ = L - 0.0894841775 * a - 1.2914855480 * b
        const l = l_ * l_ * l_, m = m_ * m_ * m_, s = s_ * s_ * s_
        let r = +4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s
        let g = -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s
        let bl = -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s
        function toSrgb(c) { return c <= 0.0031308 ? c * 12.92 : 1.055 * Math.pow(c, 1/2.4) - 0.055 }
        return Qt.rgba(
            Math.max(0, Math.min(1, toSrgb(r))),
            Math.max(0, Math.min(1, toSrgb(g))),
            Math.max(0, Math.min(1, toSrgb(bl))),
            1)
    }

    // sRGB to OKLCH (returns {L, C, H} where H is in degrees)
    function toOklch(color) {
        const r = color.r, g = color.g, b = color.b
        // sRGB to linear
        function fromSrgb(c) { return c <= 0.04045 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4) }
        const lr = fromSrgb(r), lg = fromSrgb(g), lb = fromSrgb(b)
        // Linear RGB to LMS
        const l = 0.4122214708 * lr + 0.5363325363 * lg + 0.0514459929 * lb
        const m = 0.2119034982 * lr + 0.6806995451 * lg + 0.1073969566 * lb
        const s = 0.0883024619 * lr + 0.2817188376 * lg + 0.6299787005 * lb
        // LMS to Oklab
        const l_ = Math.cbrt(l), m_ = Math.cbrt(m), s_ = Math.cbrt(s)
        const L = 0.2104542553 * l_ + 0.7936177850 * m_ - 0.0040720468 * s_
        const a = 1.9779984951 * l_ - 2.4285922050 * m_ + 0.4505937099 * s_
        const ob = 0.0259040371 * l_ + 0.7827717662 * m_ - 0.8086757660 * s_
        // Oklab to OKLCH
        const C = Math.sqrt(a * a + ob * ob)
        let H = Math.atan2(ob, a) * 180 / Math.PI
        if (H < 0) H += 360
        return { L: L, C: C, H: H }
    }

    // Adjust OKLCH values and return sRGB color
    function adjustOklch(color, dL, dC, dH) {
        const lch = toOklch(color)
        return oklch(lch.H + (dH || 0), Math.max(0, lch.C + (dC || 0)), Math.max(0, Math.min(1, lch.L + (dL || 0))))
    }

    // Ensure minimum lightness for dark theme visibility
    function ensureLightness(color, minL) {
        const lch = toOklch(color)
        if (lch.L < minL) {
            return oklch(lch.H, lch.C, minL)
        }
        return color
    }

    // Extract dominant color from pixel data (ImageData from Canvas)
    // Uses weighted frequency counting with saturation preference
    function extractDominantColor(imageData, sampleStep) {
        const data = imageData.data
        const step = sampleStep || 4
        const colorCounts = {}

        for (let i = 0; i < data.length; i += 4 * step) {
            const r = data[i], g = data[i + 1], b = data[i + 2], a = data[i + 3]
            if (a < 128) continue // Skip transparent pixels

            // Quantize to reduce noise (5-bit per channel)
            const qr = Math.floor(r / 8) * 8
            const qg = Math.floor(g / 8) * 8
            const qb = Math.floor(b / 8) * 8
            const key = (qr << 16) | (qg << 8) | qb

            // Weight by saturation (prefer vibrant colors)
            const max = Math.max(r, g, b), min = Math.min(r, g, b)
            const sat = max > 0 ? (max - min) / max : 0
            const lum = (max + min) / 510 // 0-1 range

            // Skip very dark or very light colors
            if (lum < 0.1 || lum > 0.9) continue

            // Saturation-weighted count
            const weight = 1 + sat * 2
            colorCounts[key] = (colorCounts[key] || 0) + weight
        }

        // Find most prominent color
        let maxCount = 0, dominantKey = 0
        for (const key in colorCounts) {
            if (colorCounts[key] > maxCount) {
                maxCount = colorCounts[key]
                dominantKey = parseInt(key)
            }
        }

        if (maxCount === 0) return null

        const dr = (dominantKey >> 16) & 0xFF
        const dg = (dominantKey >> 8) & 0xFF
        const db = dominantKey & 0xFF
        return Qt.rgba(dr / 255, dg / 255, db / 255, 1)
    }
}
