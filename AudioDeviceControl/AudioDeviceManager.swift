import Foundation
import CoreAudio

final class AudioDeviceManager {

    static let shared = AudioDeviceManager()

    private init() {}

    // ---------------------------------------------------------
    // MARK: - Alle Geräte holen
    // ---------------------------------------------------------

    func getAllDeviceIDs() -> [AudioDeviceID] {

        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        // 1) Größe abfragen
        var dataSize: UInt32 = 0
        var status = AudioObjectGetPropertyDataSize(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &dataSize
        )

        if status != noErr || dataSize == 0 {
            print("❌ getAllDeviceIDs() Size Error:", status, "size:", dataSize)
            return []
        }

        // 2) IDs holen
        let count = Int(dataSize) / MemoryLayout<AudioDeviceID>.size
        var ids = [AudioDeviceID](repeating: 0, count: count)

        status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &dataSize,
            &ids
        )

        if status != noErr {
            print("❌ getAllDeviceIDs() Load Error:", status)
            return []
        }

        print("🎧 getAllDeviceIDs() →", ids)
        return ids
    }

    // ---------------------------------------------------------
    // MARK: - Default Device holen
    // ---------------------------------------------------------

    func getDefaultInputDevice() -> AudioDeviceID {
        getDefaultDevice(for: kAudioHardwarePropertyDefaultInputDevice)
    }

    func getDefaultOutputDevice() -> AudioDeviceID {
        getDefaultDevice(for: kAudioHardwarePropertyDefaultOutputDevice)
    }

    private func getDefaultDevice(for selector: AudioObjectPropertySelector) -> AudioDeviceID {

        var id: AudioDeviceID = 0
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)

        var address = AudioObjectPropertyAddress(
            mSelector: selector,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &size,
            &id
        )

        if status != noErr {
            print("❌ Default Device Error:", status)
        }

        return id
    }

    // ---------------------------------------------------------
    // MARK: - Default Device setzen
    // ---------------------------------------------------------

    func setDefaultInputDevice(_ id: AudioDeviceID) {
        setDefaultDevice(id, selector: kAudioHardwarePropertyDefaultInputDevice)
    }

    func setDefaultOutputDevice(_ id: AudioDeviceID) {
        setDefaultDevice(id, selector: kAudioHardwarePropertyDefaultOutputDevice)
    }

    private func setDefaultDevice(_ id: AudioDeviceID,
                                  selector: AudioObjectPropertySelector) {

        var mutableID = id
        var address = AudioObjectPropertyAddress(
            mSelector: selector,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        let status = AudioObjectSetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            UInt32(MemoryLayout<AudioDeviceID>.size),
            &mutableID
        )

        if status != noErr {
            print("❌ setDefaultDevice Error:", status)
        }
    }

    // ---------------------------------------------------------
    // MARK: - Input / Output Erkennung
    // ---------------------------------------------------------

    func isInputDevice(_ id: AudioDeviceID) -> Bool {
        return deviceHasStream(id, direction: kAudioObjectPropertyScopeInput)
    }

    func isOutputDevice(_ id: AudioDeviceID) -> Bool {
        return deviceHasStream(id, direction: kAudioObjectPropertyScopeOutput)
    }

    private func deviceHasStream(_ id: AudioDeviceID,
                                 direction: AudioObjectPropertyScope) -> Bool {

        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreams,
            mScope: direction,
            mElement: kAudioObjectPropertyElementMain
        )

        var dataSize: UInt32 = 0
        let status = AudioObjectGetPropertyDataSize(id, &address, 0, nil, &dataSize)

        if status != noErr {
            print("❌ deviceHasStream Error:", id, direction, status)
        }

        return status == noErr && dataSize > 0
    }
}
