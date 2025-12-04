import Foundation

/// Speichert bekannte Geräte-UIDs und Metadaten (Name, Input/Output).
final class DeviceRegistry {

    static let shared = DeviceRegistry()

    private let keyUIDs  = "knownAudioDevices"                // bestehender Key (Kompatibilität)
    private let keyMeta  = "knownAudioDevicesMeta_v2"         // neuer Key für Metadaten (Codable)
    private let defaults = UserDefaults.standard

    struct Metadata: Codable {
        var name: String
        var isInput: Bool
        var isOutput: Bool
    }

    private init() {}

    // MARK: - Alte API (Kompatibilität)

    /// Liste aller gespeicherten Gerät-UIDs (Kompatibilität)
    var storedUIDs: [String] {
        get { defaults.stringArray(forKey: keyUIDs) ?? [] }
        set { defaults.set(newValue, forKey: keyUIDs) }
    }

    // MARK: - Metadaten speichern/laden

    private func loadMetaDict() -> [String: Metadata] {
        if let data = defaults.data(forKey: keyMeta) {
            if let dict = try? JSONDecoder().decode([String: Metadata].self, from: data) {
                return dict
            }
        }
        return [:]
    }

    private func saveMetaDict(_ dict: [String: Metadata]) {
        if let data = try? JSONEncoder().encode(dict) {
            defaults.set(data, forKey: keyMeta)
        }
    }

    func metadata(for uid: String) -> Metadata? {
        let dict = loadMetaDict()
        return dict[uid]
    }

    // MARK: - Registrierung

    /// Fügt ein Gerät hinzu (inkl. Metadaten) falls neu, oder aktualisiert Metadaten falls bekannt.
    func registerIfNeeded(_ device: AudioDevice) {
        // Wenn Gerät gelöscht war, entferne es aus der Deleted-Liste (wird wieder aktiviert)
        if PriorityStore.shared.isDeleted(device.uid) {
            PriorityStore.shared.removeDeletedUID(device.uid)
        }
        
        // UID-Liste pflegen (Kompatibilität)
        var list = storedUIDs
        if !list.contains(device.uid) {
            list.append(device.uid)
            storedUIDs = list
        }
        // Metadaten aktualisieren
        var meta = loadMetaDict()
        meta[device.uid] = Metadata(name: device.name, isInput: device.isInput, isOutput: device.isOutput)
        saveMetaDict(meta)
    }

    /// Registriert mehrere Geräte gleichzeitig (inkl. Metadaten).
    func registerDevices(_ devices: [AudioDevice]) {
        var uidSet = Set(storedUIDs)
        var meta = loadMetaDict()
        for dev in devices {
            // Wenn Gerät gelöscht war, entferne es aus der Deleted-Liste (wird wieder aktiviert)
            if PriorityStore.shared.isDeleted(dev.uid) {
                PriorityStore.shared.removeDeletedUID(dev.uid)
            }
            
            uidSet.insert(dev.uid)
            meta[dev.uid] = Metadata(name: dev.name, isInput: dev.isInput, isOutput: dev.isOutput)
        }
        storedUIDs = Array(uidSet)
        saveMetaDict(meta)
    }

    /// Prüft, ob ein Gerät bereits bekannt ist
    func isKnown(_ device: AudioDevice) -> Bool {
        storedUIDs.contains(device.uid)
    }
    
    // MARK: - Entfernen
    
    func removeMetadata(for uid: String) {
        var meta = loadMetaDict()
        meta.removeValue(forKey: uid)
        saveMetaDict(meta)
    }
    
    func removeDevice(_ uid: String) {
        // Entferne aus UID-Liste
        var list = storedUIDs
        list.removeAll { $0 == uid }
        storedUIDs = list
        
        // Entferne Metadaten
        removeMetadata(for: uid)
    }
}
