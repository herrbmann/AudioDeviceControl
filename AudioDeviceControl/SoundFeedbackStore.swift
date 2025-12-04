import Foundation

final class SoundFeedbackStore {
    static let shared = SoundFeedbackStore()
    
    private let keyEnabled = "soundFeedbackEnabled"
    private let keyProfileSwitch = "soundFeedbackProfileSwitch"
    private let keyDeviceSwitch = "soundFeedbackDeviceSwitch"
    private let keyError = "soundFeedbackError"
    private let keyVolume = "soundFeedbackVolume"
    
    private let defaults = UserDefaults.standard
    
    private init() {}
    
    func isEnabled() -> Bool {
        defaults.bool(forKey: keyEnabled)
    }
    
    func setEnabled(_ enabled: Bool) {
        defaults.set(enabled, forKey: keyEnabled)
    }
    
    func getProfileSwitchSound() -> String {
        defaults.string(forKey: keyProfileSwitch) ?? "system"
    }
    
    func setProfileSwitchSound(_ sound: String) {
        defaults.set(sound, forKey: keyProfileSwitch)
    }
    
    func getDeviceSwitchSound() -> String {
        defaults.string(forKey: keyDeviceSwitch) ?? "system"
    }
    
    func setDeviceSwitchSound(_ sound: String) {
        defaults.set(sound, forKey: keyDeviceSwitch)
    }
    
    func getErrorSound() -> String {
        defaults.string(forKey: keyError) ?? "system"
    }
    
    func setErrorSound(_ sound: String) {
        defaults.set(sound, forKey: keyError)
    }
    
    func getVolume() -> Int {
        let volume = defaults.integer(forKey: keyVolume)
        return volume > 0 ? volume : 30 // Default 30%
    }
    
    func setVolume(_ volume: Int) {
        defaults.set(max(0, min(100, volume)), forKey: keyVolume)
    }
}

