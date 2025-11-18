import Foundation

final class PriorityStore {

    static let shared = PriorityStore()

    private let keyInput  = "audioDevicePriorityOrder_input"
    private let keyOutput = "audioDevicePriorityOrder_output"
    private let keyIgnored = "audioDeviceIgnoredUIDs"

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

    // MARK: Ignored Devices

    func loadIgnoredUIDs() -> [String] {
        defaults.stringArray(forKey: keyIgnored) ?? []
    }

    func saveIgnoredUIDs(_ uids: [String]) {
        defaults.set(uids, forKey: keyIgnored)
    }

    func addIgnoredUID(_ uid: String) {
        var list = loadIgnoredUIDs()
        if !list.contains(uid) {
            list.append(uid)
            saveIgnoredUIDs(list)
        }
    }

    func removeIgnoredUID(_ uid: String) {
        var list = loadIgnoredUIDs()
        if let idx = list.firstIndex(of: uid) {
            list.remove(at: idx)
            saveIgnoredUIDs(list)
        }
    }

    func clearIgnoredUIDs() {
        saveIgnoredUIDs([])
    }
}
