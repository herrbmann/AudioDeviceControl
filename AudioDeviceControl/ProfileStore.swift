import Foundation

final class ProfileStore {
    
    static let shared = ProfileStore()
    
    private let keyProfiles = "audioDeviceProfiles"
    private let keyActiveProfileID = "audioDeviceActiveProfileID"
    private let keyManuallyLockedProfileID = "audioDeviceManuallyLockedProfileID"
    private let keyMigrationDone = "audioDeviceProfileMigrationDone"
    private let keyIgnoredMigrationDone = "audioDeviceIgnoredMigrationDone"
    
    private let defaults = UserDefaults.standard
    
    private init() {}
    
    // MARK: - Profiles
    
    func loadProfiles() -> [Profile] {
        guard let data = defaults.data(forKey: keyProfiles) else {
            print("📋 ProfileStore: Keine Profile-Daten gefunden")
            return []
        }
        
        do {
            let profiles = try JSONDecoder().decode([Profile].self, from: data)
            print("✅ ProfileStore: \(profiles.count) Profile erfolgreich geladen")
            return profiles
        } catch {
            print("❌ ProfileStore.loadProfiles() Error:", error)
            print("❌ Error Details:", error.localizedDescription)
            
            // Versuche Fallback: Manuelles Decodieren mit Migration
            if let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                print("🔄 ProfileStore: Versuche Fallback-Decodierung...")
                var migratedProfiles: [Profile] = []
                
                for profileDict in json {
                    if let profile = migrateProfile(from: profileDict) {
                        migratedProfiles.append(profile)
                    }
                }
                
                if !migratedProfiles.isEmpty {
                    print("✅ ProfileStore: \(migratedProfiles.count) Profile erfolgreich migriert")
                    // Speichere die migrierten Profile sofort
                    saveProfiles(migratedProfiles)
                    return migratedProfiles
                }
            }
            
            print("❌ ProfileStore: Konnte Profile nicht wiederherstellen")
            return []
        }
    }
    
    // Fallback-Migration für alte Profile-Strukturen
    private func migrateProfile(from dict: [String: Any]) -> Profile? {
        guard let idString = dict["id"] as? String,
              let id = UUID(uuidString: idString),
              let name = dict["name"] as? String,
              let icon = dict["icon"] as? String,
              let color = dict["color"] as? String else {
            return nil
        }
        
        let inputOrder = dict["inputOrder"] as? [String] ?? []
        let outputOrder = dict["outputOrder"] as? [String] ?? []
        let ignoredInputUIDs = dict["ignoredInputUIDs"] as? [String] ?? []
        let ignoredOutputUIDs = dict["ignoredOutputUIDs"] as? [String] ?? []
        let isDefault = dict["isDefault"] as? Bool ?? false
        let wifiSSID = dict["wifiSSID"] as? String
        
        return Profile(
            id: id,
            name: name,
            icon: icon,
            color: color,
            inputOrder: inputOrder,
            outputOrder: outputOrder,
            ignoredInputUIDs: ignoredInputUIDs,
            ignoredOutputUIDs: ignoredOutputUIDs,
            isDefault: isDefault,
            wifiSSID: wifiSSID
        )
    }
    
    func saveProfiles(_ profiles: [Profile]) {
        do {
            let data = try JSONEncoder().encode(profiles)
            defaults.set(data, forKey: keyProfiles)
        } catch {
            print("❌ ProfileStore.saveProfiles() Error:", error)
        }
    }
    
    // MARK: - Active Profile
    
    func loadActiveProfileID() -> UUID? {
        guard let uuidString = defaults.string(forKey: keyActiveProfileID),
              let uuid = UUID(uuidString: uuidString) else {
            return nil
        }
        return uuid
    }
    
    func saveActiveProfileID(_ id: UUID) {
        defaults.set(id.uuidString, forKey: keyActiveProfileID)
    }
    
    func clearActiveProfileID() {
        defaults.removeObject(forKey: keyActiveProfileID)
    }
    
    // MARK: - Migration
    
    func isMigrationDone() -> Bool {
        return defaults.bool(forKey: keyMigrationDone)
    }
    
    func markMigrationDone() {
        defaults.set(true, forKey: keyMigrationDone)
    }
    
    // MARK: - Ignored Devices Migration
    
    func isIgnoredMigrationDone() -> Bool {
        return defaults.bool(forKey: keyIgnoredMigrationDone)
    }
    
    func markIgnoredMigrationDone() {
        defaults.set(true, forKey: keyIgnoredMigrationDone)
    }
    
    // MARK: - Manually Locked Profile
    
    func loadManuallyLockedProfileID() -> UUID? {
        guard let uuidString = defaults.string(forKey: keyManuallyLockedProfileID),
              let uuid = UUID(uuidString: uuidString) else {
            return nil
        }
        return uuid
    }
    
    func saveManuallyLockedProfileID(_ id: UUID) {
        defaults.set(id.uuidString, forKey: keyManuallyLockedProfileID)
    }
    
    func clearManuallyLockedProfileID() {
        defaults.removeObject(forKey: keyManuallyLockedProfileID)
    }
}

