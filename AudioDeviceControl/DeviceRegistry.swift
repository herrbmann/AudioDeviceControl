import Foundation

/// Speichert nur die Liste der bekannten Device-UIDs.
/// AudioDevice selbst wird NICHT encoded.
final class DeviceRegistry {

    static let shared = DeviceRegistry()

    private let key = "knownAudioDevices"
    private let defaults = UserDefaults.standard

    private init() {}

    /// Liste aller gespeicherten Gerät-UIDs
    var storedUIDs: [String] {
        get {
            defaults.stringArray(forKey: key) ?? []
        }
        set {
            defaults.set(newValue, forKey: key)
        }
    }

    /// Fügt ein Gerät hinzu, wenn es neu ist
    func registerIfNeeded(_ device: AudioDevice) {
        var list = storedUIDs
        if !list.contains(device.uid) {
            list.append(device.uid)
            storedUIDs = list
        }
    }

    /// Registriert mehrere Geräte gleichzeitig
    func registerDevices(_ devices: [AudioDevice]) {
        var list = Set(storedUIDs)
        for dev in devices {
            list.insert(dev.uid)
        }
        storedUIDs = Array(list)
    }

    /// Prüft, ob ein Gerät bereits bekannt ist
    func isKnown(_ device: AudioDevice) -> Bool {
        storedUIDs.contains(device.uid)
    }
}
