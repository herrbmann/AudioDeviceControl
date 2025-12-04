import Foundation

final class PriorityStore {

    static let shared = PriorityStore()

    private let keyInput  = "audioDevicePriorityOrder_input"
    private let keyOutput = "audioDevicePriorityOrder_output"
    private let keyIgnored = "audioDeviceIgnoredUIDs"
    private let keyIgnoredInput = "audioDeviceIgnoredUIDs_input"
    private let keyIgnoredOutput = "audioDeviceIgnoredUIDs_output"
    private let keyDeleted = "audioDeviceDeletedUIDs"

    private let defaults = UserDefaults.standard

    private init() {}

    // MARK: Input

    func loadInputOrder() -> [String] {
        defaults.stringArray(forKey: keyInput) ?? []
    }

    func saveInputOrder(_ uids: [String]) {
        defaults.set(uids, forKey: keyInput)
    }

    // MARK: Output

    func loadOutputOrder() -> [String] {
        defaults.stringArray(forKey: keyOutput) ?? []
    }

    func saveOutputOrder(_ uids: [String]) {
        defaults.set(uids, forKey: keyOutput)
    }

    // MARK: Ignored Devices (LEGACY - nicht mehr verwendet, Ignore ist jetzt pro Profil)
    // Diese Methoden bleiben für Rückwärtskompatibilität, werden aber nicht mehr aktiv verwendet
    
    @available(*, deprecated, message: "Ignored devices are now profile-based. Use Profile.ignoredInputUIDs/ignoredOutputUIDs instead.")
    func loadIgnoredUIDs() -> [String] {
        // Kombiniere Input und Output für Rückwärtskompatibilität
        let input = loadIgnoredInputUIDs()
        let output = loadIgnoredOutputUIDs()
        return Array(Set(input + output))
    }
    
    @available(*, deprecated, message: "Ignored devices are now profile-based.")
    func loadIgnoredInputUIDs() -> [String] {
        defaults.stringArray(forKey: keyIgnoredInput) ?? []
    }
    
    @available(*, deprecated, message: "Ignored devices are now profile-based.")
    func saveIgnoredInputUIDs(_ uids: [String]) {
        defaults.set(uids, forKey: keyIgnoredInput)
    }
    
    @available(*, deprecated, message: "Ignored devices are now profile-based.")
    func addIgnoredInputUID(_ uid: String) {
        var list = loadIgnoredInputUIDs()
        if !list.contains(uid) {
            list.append(uid)
            saveIgnoredInputUIDs(list)
        }
    }
    
    @available(*, deprecated, message: "Ignored devices are now profile-based.")
    func removeIgnoredInputUID(_ uid: String) {
        var list = loadIgnoredInputUIDs()
        if let idx = list.firstIndex(of: uid) {
            list.remove(at: idx)
            saveIgnoredInputUIDs(list)
        }
    }
    
    @available(*, deprecated, message: "Ignored devices are now profile-based.")
    func loadIgnoredOutputUIDs() -> [String] {
        defaults.stringArray(forKey: keyIgnoredOutput) ?? []
    }
    
    @available(*, deprecated, message: "Ignored devices are now profile-based.")
    func saveIgnoredOutputUIDs(_ uids: [String]) {
        defaults.set(uids, forKey: keyIgnoredOutput)
    }
    
    @available(*, deprecated, message: "Ignored devices are now profile-based.")
    func addIgnoredOutputUID(_ uid: String) {
        var list = loadIgnoredOutputUIDs()
        if !list.contains(uid) {
            list.append(uid)
            saveIgnoredOutputUIDs(list)
        }
    }
    
    @available(*, deprecated, message: "Ignored devices are now profile-based.")
    func removeIgnoredOutputUID(_ uid: String) {
        var list = loadIgnoredOutputUIDs()
        if let idx = list.firstIndex(of: uid) {
            list.remove(at: idx)
            saveIgnoredOutputUIDs(list)
        }
    }
    
    @available(*, deprecated, message: "Ignored devices are now profile-based.")
    func saveIgnoredUIDs(_ uids: [String]) {
        // Legacy: Speichere in beiden Listen für Migration
        saveIgnoredInputUIDs(uids)
        saveIgnoredOutputUIDs(uids)
    }

    @available(*, deprecated, message: "Ignored devices are now profile-based.")
    func addIgnoredUID(_ uid: String) {
        // Legacy: Füge zu beiden Listen hinzu
        addIgnoredInputUID(uid)
        addIgnoredOutputUID(uid)
    }

    @available(*, deprecated, message: "Ignored devices are now profile-based.")
    func removeIgnoredUID(_ uid: String) {
        // Legacy: Entferne aus beiden Listen
        removeIgnoredInputUID(uid)
        removeIgnoredOutputUID(uid)
    }

    @available(*, deprecated, message: "Ignored devices are now profile-based.")
    func clearIgnoredUIDs() {
        saveIgnoredInputUIDs([])
        saveIgnoredOutputUIDs([])
    }
    
    // MARK: Deleted Devices (komplett aus Gedächtnis entfernt)
    
    func loadDeletedUIDs() -> [String] {
        defaults.stringArray(forKey: keyDeleted) ?? []
    }
    
    func saveDeletedUIDs(_ uids: [String]) {
        defaults.set(uids, forKey: keyDeleted)
    }
    
    func addDeletedUID(_ uid: String) {
        var list = loadDeletedUIDs()
        if !list.contains(uid) {
            list.append(uid)
            saveDeletedUIDs(list)
        }
    }
    
    func removeDeletedUID(_ uid: String) {
        var list = loadDeletedUIDs()
        if let idx = list.firstIndex(of: uid) {
            list.remove(at: idx)
            saveDeletedUIDs(list)
        }
    }
    
    func clearDeletedUIDs() {
        saveDeletedUIDs([])
    }
    
    func isDeleted(_ uid: String) -> Bool {
        loadDeletedUIDs().contains(uid)
    }
}
