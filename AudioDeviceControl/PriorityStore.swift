import Foundation

final class PriorityStore {

    static let shared = PriorityStore()

    private let keyInput  = "audioDevicePriorityOrder_input"
    private let keyOutput = "audioDevicePriorityOrder_output"
    private let keyIgnored = "audioDeviceIgnoredUIDs"
    private let keyIgnoredInput = "audioDeviceIgnoredUIDs_input"
    private let keyIgnoredOutput = "audioDeviceIgnoredUIDs_output"

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

    // MARK: Ignored Devices (Legacy - für Migration)
    
    func loadIgnoredUIDs() -> [String] {
        // Kombiniere Input und Output für Rückwärtskompatibilität
        let input = loadIgnoredInputUIDs()
        let output = loadIgnoredOutputUIDs()
        return Array(Set(input + output))
    }
    
    // MARK: Ignored Input Devices
    
    func loadIgnoredInputUIDs() -> [String] {
        defaults.stringArray(forKey: keyIgnoredInput) ?? []
    }
    
    func saveIgnoredInputUIDs(_ uids: [String]) {
        defaults.set(uids, forKey: keyIgnoredInput)
    }
    
    func addIgnoredInputUID(_ uid: String) {
        var list = loadIgnoredInputUIDs()
        if !list.contains(uid) {
            list.append(uid)
            saveIgnoredInputUIDs(list)
        }
    }
    
    func removeIgnoredInputUID(_ uid: String) {
        var list = loadIgnoredInputUIDs()
        if let idx = list.firstIndex(of: uid) {
            list.remove(at: idx)
            saveIgnoredInputUIDs(list)
        }
    }
    
    // MARK: Ignored Output Devices
    
    func loadIgnoredOutputUIDs() -> [String] {
        defaults.stringArray(forKey: keyIgnoredOutput) ?? []
    }
    
    func saveIgnoredOutputUIDs(_ uids: [String]) {
        defaults.set(uids, forKey: keyIgnoredOutput)
    }
    
    func addIgnoredOutputUID(_ uid: String) {
        var list = loadIgnoredOutputUIDs()
        if !list.contains(uid) {
            list.append(uid)
            saveIgnoredOutputUIDs(list)
        }
    }
    
    func removeIgnoredOutputUID(_ uid: String) {
        var list = loadIgnoredOutputUIDs()
        if let idx = list.firstIndex(of: uid) {
            list.remove(at: idx)
            saveIgnoredOutputUIDs(list)
        }
    }
    
    // MARK: Legacy Support (für Migration)
    
    func saveIgnoredUIDs(_ uids: [String]) {
        // Legacy: Speichere in beiden Listen für Migration
        saveIgnoredInputUIDs(uids)
        saveIgnoredOutputUIDs(uids)
    }

    func addIgnoredUID(_ uid: String) {
        // Legacy: Füge zu beiden Listen hinzu
        addIgnoredInputUID(uid)
        addIgnoredOutputUID(uid)
    }

    func removeIgnoredUID(_ uid: String) {
        // Legacy: Entferne aus beiden Listen
        removeIgnoredInputUID(uid)
        removeIgnoredOutputUID(uid)
    }

    func clearIgnoredUIDs() {
        saveIgnoredInputUIDs([])
        saveIgnoredOutputUIDs([])
    }
}
