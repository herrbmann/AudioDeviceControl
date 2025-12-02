import Foundation

final class WiFiStore {
    
    static let shared = WiFiStore()
    
    private let keyWiFiAutoSwitchEnabled = "wifiAutoSwitchEnabled"
    
    private let defaults = UserDefaults.standard
    
    private init() {}
    
    // MARK: - WiFi Auto Switch Enabled
    
    func isWiFiAutoSwitchEnabled() -> Bool {
        // Default: false (deaktiviert by default)
        if defaults.object(forKey: keyWiFiAutoSwitchEnabled) == nil {
            return false
        }
        return defaults.bool(forKey: keyWiFiAutoSwitchEnabled)
    }
    
    func setWiFiAutoSwitchEnabled(_ enabled: Bool) {
        defaults.set(enabled, forKey: keyWiFiAutoSwitchEnabled)
    }
}

