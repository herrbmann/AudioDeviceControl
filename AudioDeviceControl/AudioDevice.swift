import Foundation
import CoreAudio
import AppKit

// ---------------------------------------------------------
// MARK: - AudioDevice Model
// ---------------------------------------------------------

enum DeviceState {
    case active
    case connected
    case offline
}

struct AudioDevice: Identifiable, Equatable {

    let id: AudioDeviceID
    let name: String
    let uid: String
    let isInput: Bool
    let isOutput: Bool
    let isAlive: Bool
    let isDefault: Bool

    var state: DeviceState {
        if !isAlive { return .offline }
        return isDefault ? .active : .connected
    }
    
    var identityKey: String { persistentUID + "|" + stateKey }
    private var stateKey: String {
        switch state {
        case .active: return "A"
        case .connected: return "C"
        case .offline: return "O"
        }
    }

    var persistentUID: String { uid }
    var isConnected: Bool { isAlive }

    var statusColorNS: NSColor {
        switch state {
        case .offline:
            return .systemGray
        case .active:
            return .systemGreen
        case .connected:
            return .systemBlue
        }
    }

    var iconNSImage: NSImage {
        func sym(_ name: String) -> NSImage {
            NSImage(systemSymbolName: name, accessibilityDescription: nil) ?? NSImage()
        }

        let lower = name.lowercased()

        if isOutput {
            // Headphones / Headset / AirPods
            if lower.contains("airpods") || lower.contains("headphone") || lower.contains("headset") {
                return sym("headphones")
            }
            // External speakers / HiFi speakers → use generic speaker as default
            if lower.contains("hifi") || lower.contains("hi-fi") || lower.contains("speaker") {
                return sym("speaker.wave.2.fill")
            }
            // Displays / Monitors / HDMI / TV
            if lower.contains("display") || lower.contains("monitor") || lower.contains("hdmi") {
                return sym("display")
            }
            if lower.contains("tv") {
                return sym("tv")
            }
            // Fallback for output
            return sym("speaker.wave.2.fill")
        }

        if isInput {
            // Headset microphones / AirPods
            if lower.contains("airpods") || lower.contains("headset") || lower.contains("headphone") {
                return sym("headphones")
            }
            // Built-in / internal mics
            if lower.contains("built-in") || lower.contains("builtin") || lower.contains("internal") {
                return sym("mic.fill")
            }
            // USB / external mics (generic mic symbol)
            if lower.contains("usb") || lower.contains("mic") || lower.contains("microphone") {
                return sym("mic.fill")
            }
            // Fallback for input
            return sym("mic.fill")
        }

        return sym("circle")
    }

    static func == (lhs: AudioDevice, rhs: AudioDevice) -> Bool {
        lhs.uid == rhs.uid
    }
}

// ---------------------------------------------------------
// MARK: - AudioDeviceFactory
// ---------------------------------------------------------

final class AudioDeviceFactory {

    static func make(
        from id: AudioDeviceID,
        isInput: Bool,
        isOutput: Bool,
        defaultInputID: AudioDeviceID,
        defaultOutputID: AudioDeviceID
    ) -> AudioDevice? {

        guard let name = getName(of: id) else {
            print("❌ No name for device:", id)
            return nil
        }

        guard let uid = getUID(of: id) else {
            print("❌ No UID for device:", id)
            return nil
        }

        let alive = getIsAlive(id)

        let isDefault = (isInput && id == defaultInputID)
            || (isOutput && id == defaultOutputID)

        print("🧩 Device OK:", name, uid, "input:", isInput, "output:", isOutput, "alive:", alive)

        return AudioDevice(
            id: id,
            name: name,
            uid: uid,
            isInput: isInput,
            isOutput: isOutput,
            isAlive: alive,
            isDefault: isDefault
        )
    }

    // ---------------------------------------------------------
    // MARK: - Name
    // ---------------------------------------------------------

    private static func getName(of id: AudioDeviceID) -> String? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioObjectPropertyName,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var dataSize: UInt32 = 0
        if AudioObjectGetPropertyDataSize(id, &address, 0, nil, &dataSize) != noErr {
            return nil
        }

        var cfString: CFString? = nil
        let status = withUnsafeMutablePointer(to: &cfString) {
            AudioObjectGetPropertyData(id, &address, 0, nil, &dataSize, $0)
        }

        return (status == noErr) ? (cfString as String?) : nil
    }

    // ---------------------------------------------------------
    // MARK: - UID
    // ---------------------------------------------------------

    private static func getUID(of id: AudioDeviceID) -> String? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceUID,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var dataSize: UInt32 = 0
        if AudioObjectGetPropertyDataSize(id, &address, 0, nil, &dataSize) != noErr {
            return nil
        }

        var cfString: CFString? = nil
        let status = withUnsafeMutablePointer(to: &cfString) {
            AudioObjectGetPropertyData(id, &address, 0, nil, &dataSize, $0)
        }

        return (status == noErr) ? (cfString as String?) : nil
    }

    // ---------------------------------------------------------
    // MARK: - Alive
    // ---------------------------------------------------------

    private static func getIsAlive(_ id: AudioDeviceID) -> Bool {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceIsAlive,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var alive: UInt32 = 0
        var size = UInt32(MemoryLayout<UInt32>.size)

        let status = AudioObjectGetPropertyData(
            id, &address, 0, nil, &size, &alive
        )

        return status == noErr && alive != 0
    }

    // ---------------------------------------------------------
    // MARK: - Offline Placeholder
    // ---------------------------------------------------------

    static func makeOffline(uid: String,
                            name: String,
                            isInput: Bool,
                            isOutput: Bool) -> AudioDevice {

        let fake = fakeID(forUID: uid)
        return AudioDevice(
            id: fake,
            name: name,
            uid: uid,
            isInput: isInput,
            isOutput: isOutput,
            isAlive: false,
            isDefault: false
        )
    }

    /// Deterministic 32-bit hash for stable fake IDs (FNV-1a)
    private static func fakeID(forUID uid: String) -> AudioDeviceID {
        var hash: UInt32 = 2166136261
        for byte in uid.utf8 {
            hash ^= UInt32(byte)
            hash &*= 16777619
        }
        // Set high bit to reduce collision with real IDs
        let withFlag = hash | 0x8000_0000
        return AudioDeviceID(withFlag)
    }
}
