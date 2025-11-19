import Foundation

final class UpdateStore {
    
    static let shared = UpdateStore()
    
    private let keyUpdateCheckEnabled = "updateCheckerEnabled"
    private let keyLastUpdateCheckDate = "lastUpdateCheckDate"
    
    private let defaults = UserDefaults.standard
    
    private init() {}
    
    // MARK: - Update Check Enabled
    
    func isUpdateCheckEnabled() -> Bool {
        // Default: true (enabled by default)
        if defaults.object(forKey: keyUpdateCheckEnabled) == nil {
            return true
        }
        return defaults.bool(forKey: keyUpdateCheckEnabled)
    }
    
    func setUpdateCheckEnabled(_ enabled: Bool) {
        defaults.set(enabled, forKey: keyUpdateCheckEnabled)
    }
    
    // MARK: - Last Check Date
    
    func getLastCheckDate() -> Date? {
        return defaults.object(forKey: keyLastUpdateCheckDate) as? Date
    }
    
    func setLastCheckDate(_ date: Date) {
        defaults.set(date, forKey: keyLastUpdateCheckDate)
    }
}

