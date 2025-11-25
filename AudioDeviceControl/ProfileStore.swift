import Foundation

final class ProfileStore {
    
    static let shared = ProfileStore()
    
    private let keyProfiles = "audioDeviceProfiles"
    private let keyActiveProfileID = "audioDeviceActiveProfileID"
    private let keyMigrationDone = "audioDeviceProfileMigrationDone"
    private let keyIgnoredMigrationDone = "audioDeviceIgnoredMigrationDone"
    
    private let defaults = UserDefaults.standard
    
    private init() {}
    
    // MARK: - Profiles
    
    func loadProfiles() -> [Profile] {
        guard let data = defaults.data(forKey: keyProfiles) else {
            return []
        }
        
        do {
            let profiles = try JSONDecoder().decode([Profile].self, from: data)
            return profiles
        } catch {
            print("❌ ProfileStore.loadProfiles() Error:", error)
            return []
        }
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
}

