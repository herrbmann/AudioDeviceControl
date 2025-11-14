import Foundation

final class PriorityStore {

    static let shared = PriorityStore()

    private let keyInput  = "audioDevicePriorityOrder_input"
    private let keyOutput = "audioDevicePriorityOrder_output"

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
}
