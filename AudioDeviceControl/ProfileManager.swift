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
        performMigrationIfNeeded()
        performIgnoredDevicesMigrationIfNeeded()
        loadActiveProfile()
    }
    
    // MARK: - Load & Save
    
    private func loadProfiles() {
        profiles = store.loadProfiles()
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
            return
        }
        
        // Prüfe ob bereits Profile existieren
        if !profiles.isEmpty {
            store.markMigrationDone()
            return
        }
        
        // Migriere bestehende Prioritäten zu Default-Profil
        let inputOrder = priorityStore.loadInputOrder()
        let outputOrder = priorityStore.loadOutputOrder()
        
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
        store.markMigrationDone()
        
        print("✅ Migration: Default-Profil erstellt mit \(inputOrder.count) Input- und \(outputOrder.count) Output-Geräten")
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
    
    // MARK: - Helper
    
    func getProfile(by id: UUID) -> Profile? {
        return profiles.first { $0.id == id }
    }
}

