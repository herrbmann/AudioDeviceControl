import Cocoa

class DeviceIconResolver {

    static func icon(for deviceName: String) -> NSImage {
        let lower = deviceName.lowercased()

        // AirPods
        if lower.contains("airpods") {
            return NSImage(systemSymbolName: "airpodspro", accessibilityDescription: nil) ?? defaultIcon()
        }

        // Headphones / Headset
        if lower.contains("headset") || lower.contains("headphones") || lower.contains("buds") {
            return NSImage(systemSymbolName: "headphones", accessibilityDescription: nil) ?? defaultIcon()
        }

        // Built-in Mic
        if lower.contains("built-in") || lower.contains("internal") {
            return NSImage(systemSymbolName: "mic.fill", accessibilityDescription: nil) ?? defaultIcon()
        }

        // Display audio
        if lower.contains("display") {
            return NSImage(systemSymbolName: "display", accessibilityDescription: nil) ?? defaultIcon()
        }

        // USB Mics
        if lower.contains("usb") {
            return NSImage(systemSymbolName: "mic.fill", accessibilityDescription: nil) ?? defaultIcon()
        }

        // Generic microphones
        if lower.contains("mic") || lower.contains("microphone") {
            return NSImage(systemSymbolName: "mic.fill", accessibilityDescription: nil) ?? defaultIcon()
        }

        // Generic speakers
        return defaultIcon()
    }

    private static func defaultIcon() -> NSImage {
        NSImage(systemSymbolName: "hifispeaker.fill", accessibilityDescription: nil)!
    }
}
