import Foundation
import CoreAudio
import AppKit

// ---------------------------------------------------------
// MARK: - AudioDevice Model
// ---------------------------------------------------------

struct AudioDevice: Identifiable, Equatable {

    let id: AudioDeviceID
    let name: String
    let uid: String
    let isInput: Bool
    let isOutput: Bool
    let isAlive: Bool
    let isDefault: Bool

    var persistentUID: String { uid }
    var isConnected: Bool { isAlive }

    var statusColorNS: NSColor {
        if !isAlive { return .systemGray }
        if isDefault { return .systemGreen }
        return .systemBlue
    }

    var iconNSImage: NSImage {
        if isInput {
            return NSImage(systemSymbolName: "mic.fill", accessibilityDescription: nil) ?? NSImage()
        }
        if isOutput {
            return NSImage(systemSymbolName: "speaker.wave.2.fill", accessibilityDescription: nil) ?? NSImage()
        }
        return NSImage(systemSymbolName: "circle", accessibilityDescription: nil) ?? NSImage()
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
}
