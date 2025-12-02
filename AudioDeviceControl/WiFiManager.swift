import Foundation
import CoreWLAN
import CoreLocation
import AppKit

final class WiFiManager: NSObject {
    static let shared = WiFiManager()
    
    private let locationManager = CLLocationManager()
    private var permissionRequested = false
    
    private override init() {
        super.init()
        locationManager.delegate = nil // Wir brauchen keinen Delegate, nur die Berechtigung
    }
    
    /// Fordert Location Services Berechtigung an
    func requestLocationPermission() {
        guard !permissionRequested else { return }
        permissionRequested = true
        
        let status = locationManager.authorizationStatus
        print("📡 WiFiManager: Location Services Status: \(status.rawValue)")
        
        if status == .notDetermined {
            print("📡 WiFiManager: Frage nach Location Services Berechtigung...")
            locationManager.requestWhenInUseAuthorization()
        } else if status == .denied || status == .restricted {
            print("📡 WiFiManager: Location Services Berechtigung verweigert")
        } else {
            print("📡 WiFiManager: Location Services Berechtigung bereits erteilt")
        }
    }
    
    /// Prüft ob Location Services Berechtigung verfügbar ist
    /// - Returns: `true` wenn SSID abrufbar ist, `false` wenn Berechtigung fehlt
    func hasLocationPermission() -> Bool {
        let status = locationManager.authorizationStatus
        if status == .notDetermined {
            // Noch nicht angefragt - frage jetzt
            requestLocationPermission()
            return false
        }
        
        let client = CWWiFiClient.shared()
        guard let interface = client.interface(), interface.powerOn() else {
            return false
        }
        
        // Wenn SSID abrufbar ist, haben wir die Berechtigung
        return interface.ssid() != nil
    }
    
    /// Gibt die SSID des aktuell verbundenen WiFi-Netzwerks zurück
    /// - Returns: Die SSID als String, oder `nil` wenn kein WiFi verbunden ist
    func getCurrentSSID() -> String? {
        let client = CWWiFiClient.shared()
        
        // Prüfe ob WiFi überhaupt verfügbar ist
        guard let interface = client.interface() else {
            print("📡 WiFiManager: Keine WiFi-Interface gefunden")
            return nil
        }
        
        // Prüfe ob WiFi aktiviert ist
        guard interface.powerOn() else {
            print("📡 WiFiManager: WiFi ist nicht aktiviert")
            return nil
        }
        
        // Hole SSID
        // WICHTIG: In macOS benötigt CoreWLAN Location Services Berechtigung, um die SSID abzurufen
        if let ssid = interface.ssid() {
            print("📡 WiFiManager: Aktuelle SSID: \(ssid)")
            return ssid
        } else {
            print("📡 WiFiManager: ⚠️ Keine SSID verfügbar - Location Services Berechtigung fehlt")
            return nil
        }
    }
    
    /// Öffnet die System Settings für Location Services
    func openLocationSettings() {
        // Versuche verschiedene URLs für verschiedene macOS Versionen
        let urls = [
            "x-apple.systempreferences:com.apple.preference.security?Privacy_LocationServices", // macOS 13+
            "x-apple.systempreferences:com.apple.preference.security?Privacy", // Fallback
        ]
        
        for urlString in urls {
            if let url = URL(string: urlString) {
                if NSWorkspace.shared.open(url) {
                    print("📡 WiFiManager: System Settings geöffnet: \(urlString)")
                    return
                }
            }
        }
        
        // Fallback: Öffne System Settings allgemein
        if let url = URL(string: "x-apple.systempreferences:") {
            NSWorkspace.shared.open(url)
            print("📡 WiFiManager: System Settings geöffnet (Fallback)")
        }
    }
}

