import Foundation
import UserNotifications

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
        
        let profileManager = ProfileManager.shared
        
        // Suche Profil mit dieser SSID
        if let matchingProfile = profileManager.profiles.first(where: { $0.wifiSSID == ssid }) {
            // Nur wechseln, wenn es nicht bereits aktiv ist
            if profileManager.activeProfile?.id != matchingProfile.id {
                // WiFi-Wechsel: Immer wechseln, auch wenn aktuelles Profil gesperrt ist
                // Die Sperre wird beim WiFi-Wechsel aufgehoben
                print("📡 WiFiWatcher: Wechsle zu Profil: \(matchingProfile.name) (WiFi-Wechsel)")
                // Sperre aufheben beim automatischen WiFi-Wechsel
                profileManager.setManuallyLocked(nil)
                profileManager.setActiveProfile(matchingProfile)
                AudioState.shared.switchToProfile(matchingProfile)
                
                // Sende Notification über automatischen Profil-Wechsel
                NotificationManager.shared.notifyProfileSwitch(wifiSSID: ssid, profileName: matchingProfile.name)
            } else {
                // Profil ist bereits aktiv - keine Aktion nötig
                print("📡 WiFiWatcher: Profil '\(matchingProfile.name)' ist bereits aktiv")
            }
        } else {
            // Kein Profil für dieses WiFi gefunden
            // Wenn aktuelles Profil gesperrt ist, bleibt es aktiv
            // Wenn nicht gesperrt, bleibt es auch aktiv (kein Wechsel nötig)
            if profileManager.isActiveProfileManuallyLocked() {
                print("📡 WiFiWatcher: Kein Profil für SSID '\(ssid)' gefunden - gesperrtes Profil bleibt aktiv")
            } else {
                print("📡 WiFiWatcher: Kein Profil für SSID '\(ssid)' gefunden - aktuelles Profil bleibt aktiv")
            }
        }
    }
}

