import Foundation

final class WiFiWatcher {
    static let shared = WiFiWatcher()
    
    private var currentSSID: String?
    private var timer: Timer?
    private let checkInterval: TimeInterval = 2.0 // Alle 2 Sekunden prüfen
    private var isEnabled: Bool = false
    private let wifiStore = WiFiStore.shared
    
    private init() {
        // Starte automatisch, wenn Feature aktiviert ist
        if wifiStore.isWiFiAutoSwitchEnabled() {
            startWatching()
        }
    }
    
    func startWatching() {
        guard !isEnabled else { return }
        isEnabled = true
        
        // Initiale Prüfung
        checkWiFiAndSwitchProfile()
        
        // Regelmäßige Prüfung
        timer = Timer.scheduledTimer(withTimeInterval: checkInterval, repeats: true) { [weak self] _ in
            self?.checkWiFiAndSwitchProfile()
        }
    }
    
    func stopWatching() {
        isEnabled = false
        timer?.invalidate()
        timer = nil
    }
    
    func updateEnabledState() {
        if wifiStore.isWiFiAutoSwitchEnabled() {
            if !isEnabled {
                startWatching()
            }
        } else {
            if isEnabled {
                stopWatching()
            }
        }
    }
    
    private func checkWiFiAndSwitchProfile() {
        // Prüfe ob Feature aktiviert ist
        guard wifiStore.isWiFiAutoSwitchEnabled() else {
            if isEnabled {
                stopWatching()
            }
            return
        }
        
        let newSSID = WiFiManager.shared.getCurrentSSID()
        
        // Nur reagieren, wenn sich die SSID geändert hat
        guard newSSID != currentSSID else { return }
        
        currentSSID = newSSID
        
        // Wenn kein WiFi verbunden, nichts tun (aktuelles Profil bleibt aktiv)
        guard let ssid = newSSID else {
            print("📡 WiFiWatcher: Kein WiFi verbunden")
            return
        }
        
        print("📡 WiFiWatcher: WiFi geändert zu: \(ssid)")
        
        // Suche Profil mit dieser SSID
        let profileManager = ProfileManager.shared
        if let matchingProfile = profileManager.profiles.first(where: { $0.wifiSSID == ssid }) {
            // Nur wechseln, wenn es nicht bereits aktiv ist
            if profileManager.activeProfile?.id != matchingProfile.id {
                print("📡 WiFiWatcher: Wechsle zu Profil: \(matchingProfile.name)")
                profileManager.setActiveProfile(matchingProfile)
                AudioState.shared.switchToProfile(matchingProfile)
            }
        } else {
            print("📡 WiFiWatcher: Kein Profil für SSID '\(ssid)' gefunden - aktuelles Profil bleibt aktiv")
            // Bei unbekanntem WiFi kein Wechsel - aktuelles Profil bleibt aktiv
        }
    }
}

