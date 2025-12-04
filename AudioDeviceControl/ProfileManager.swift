import Foundation
import Combine

final class ProfileManager: ObservableObject {
    
    static let shared = ProfileManager()
    
    @Published var profiles: [Profile] = []
    @Published var activeProfile: Profile?
    
    private let store = ProfileStore.shared
    private let priorityStore = PriorityStore.shared
    
    private init() {
        loadProfiles()
        print("📋 ProfileManager: Nach loadProfiles() - \(profiles.count) Profile geladen")
        performMigrationIfNeeded()
        performIgnoredDevicesMigrationIfNeeded()
        performProfileIgnoredDevicesMigrationIfNeeded()
        loadActiveProfile()
        print("📋 ProfileManager: Final - \(profiles.count) Profile vorhanden")
    }
    
    // MARK: - Load & Save
    
    private func loadProfiles() {
        let loaded = store.loadProfiles()
        profiles = loaded
        print("📋 ProfileManager.loadProfiles(): \(loaded.count) Profile geladen")
    }
    
    private func saveProfiles() {
        store.saveProfiles(profiles)
    }
    
    private func loadActiveProfile() {
        guard let activeID = store.loadActiveProfileID() else {
            // Wenn kein aktives Profil, nimm das erste oder Default
            if let defaultProfile = profiles.first(where: { $0.isDefault }) ?? profiles.first {
                setActiveProfile(defaultProfile)
            }
            return
        }
        
        if let profile = profiles.first(where: { $0.id == activeID }) {
            activeProfile = profile
        } else {
            // Profil nicht gefunden, nimm Default oder erstes
            if let defaultProfile = profiles.first(where: { $0.isDefault }) ?? profiles.first {
                setActiveProfile(defaultProfile)
            }
        }
    }
    
    // MARK: - Profile Management
    
    func createProfile(name: String, icon: String, color: String) -> Profile {
        let profile = Profile(
            name: name,
            icon: icon,
            color: color
        )
        profiles.append(profile)
        saveProfiles()
        return profile
    }
    
    func updateProfile(_ profile: Profile) {
        guard let index = profiles.firstIndex(where: { $0.id == profile.id }) else {
            return
        }
        profiles[index] = profile
        saveProfiles()
        
        // Wenn es das aktive Profil ist, aktualisiere es
        if activeProfile?.id == profile.id {
            activeProfile = profile
        }
    }
    
    func deleteProfile(_ profile: Profile) {
        profiles.removeAll { $0.id == profile.id }
        saveProfiles()
        
        // Wenn das gelöschte Profil aktiv war, wechsle zu einem anderen
        if activeProfile?.id == profile.id {
            if let defaultProfile = profiles.first(where: { $0.isDefault }) ?? profiles.first {
                setActiveProfile(defaultProfile)
            } else {
                activeProfile = nil
            }
        }
    }
    
    func clearAllProfiles() {
        profiles.removeAll()
        activeProfile = nil
        saveProfiles()
        store.clearActiveProfileID()
    }
    
    func setActiveProfile(_ profile: Profile) {
        guard profiles.contains(where: { $0.id == profile.id }) else {
            return
        }
        activeProfile = profile
        store.saveActiveProfileID(profile.id)
    }
    
    // MARK: - Migration
    
    private func performMigrationIfNeeded() {
        guard !store.isMigrationDone() else {
            print("📋 Migration bereits durchgeführt")
            return
        }
        
        // WICHTIG: Prüfe ob bereits Profile existieren - wenn ja, überspringe Migration
        if !profiles.isEmpty {
            print("✅ Migration übersprungen: \(profiles.count) Profile bereits vorhanden")
            store.markMigrationDone()
            return
        }
        
        // Nur wenn KEINE Profile existieren: Migriere bestehende Prioritäten zu Default-Profil
        let inputOrder = priorityStore.loadInputOrder()
        let outputOrder = priorityStore.loadOutputOrder()
        
        // Nur wenn es Prioritäten gibt, erstelle ein Default-Profil
        if !inputOrder.isEmpty || !outputOrder.isEmpty {
            let defaultProfile = Profile(
                name: "Default",
                icon: "🎧",
                color: ProfileColorPreset.colors[0].hex, // Blau
                inputOrder: inputOrder,
                outputOrder: outputOrder,
                isDefault: true
            )
            
            profiles.append(defaultProfile)
            saveProfiles()
            print("✅ Migration: Default-Profil erstellt mit \(inputOrder.count) Input- und \(outputOrder.count) Output-Geräten")
        }
        
        store.markMigrationDone()
    }
    
    private func performIgnoredDevicesMigrationIfNeeded() {
        guard !store.isIgnoredMigrationDone() else {
            return
        }
        
        // Die ignoredUIDs aus der ersten Migration sind bereits in PriorityStore
        // und werden jetzt global verwendet. Wir müssen nichts weiter tun.
        // Alte Profile mit ignoredUIDs werden beim Decodieren ignoriert (da das Feld entfernt wurde)
        // und die ignoredUIDs sind bereits in der globalen Liste.
        
        store.markIgnoredMigrationDone()
        
        print("✅ Ignored Devices Migration: Abgeschlossen - Ignored Devices sind jetzt global")
    }
    
    private func performProfileIgnoredDevicesMigrationIfNeeded() {
        // Stelle sicher, dass alle Profile die neuen ignoredInputUIDs und ignoredOutputUIDs Properties haben
        // Der Custom Decoder sollte sie bereits mit leeren Arrays initialisiert haben,
        // aber wir speichern die Profile explizit, um sicherzustellen, dass sie persistiert werden
        var needsSave = false
        
        for i in profiles.indices {
            // Stelle sicher, dass die Properties existieren (sollten durch Custom Decoder bereits gesetzt sein)
            // Aber wir speichern sie explizit, um sicherzustellen, dass sie in UserDefaults gespeichert werden
            needsSave = true
        }
        
        if needsSave && !profiles.isEmpty {
            saveProfiles()
            print("✅ Profile Ignored Devices Migration: \(profiles.count) Profile aktualisiert mit ignoredInputUIDs und ignoredOutputUIDs")
        }
    }
    
    // MARK: - Default Profile Management
    
    func setDefaultProfile(_ profile: Profile) {
        guard let index = profiles.firstIndex(where: { $0.id == profile.id }) else {
            return
        }
        
        // Entferne isDefault von allen anderen Profilen
        for i in profiles.indices {
            profiles[i].isDefault = false
        }
        
        // Setze dieses Profil als Default
        profiles[index].isDefault = true
        saveProfiles()
        
        // Aktualisiere activeProfile falls nötig
        if activeProfile?.id == profile.id {
            activeProfile = profiles[index]
        }
    }
    
    func getDefaultProfile() -> Profile? {
        return profiles.first(where: { $0.isDefault })
    }
    
    // MARK: - WiFi Helper
    
    func getAllKnownWiFiSSIDs() -> [String] {
        let ssids = profiles.compactMap { $0.wifiSSID }
        // Entferne Duplikate und sortiere
        return Array(Set(ssids)).sorted()
    }
    
    // MARK: - Helper
    
    func getProfile(by id: UUID) -> Profile? {
        return profiles.first { $0.id == id }
    }
    
    // MARK: - Manual Lock Management
    
    /// Setzt ein Profil als manuell gesperrt (wird nicht durch WiFi-Wechsel überschrieben)
    func setManuallyLocked(_ profile: Profile?) {
        if let profile = profile {
            store.saveManuallyLockedProfileID(profile.id)
            print("🔒 Profil '\(profile.name)' wurde manuell gesperrt")
        } else {
            store.clearManuallyLockedProfileID()
            print("🔓 Manuelle Sperre wurde aufgehoben")
        }
    }
    
    /// Prüft ob ein Profil manuell gesperrt ist
    func isManuallyLocked(_ profile: Profile) -> Bool {
        guard let lockedID = store.loadManuallyLockedProfileID() else {
            return false
        }
        return profile.id == lockedID
    }
    
    /// Prüft ob das aktive Profil manuell gesperrt ist
    func isActiveProfileManuallyLocked() -> Bool {
        guard let activeProfile = activeProfile else {
            return false
        }
        return isManuallyLocked(activeProfile)
    }
}

