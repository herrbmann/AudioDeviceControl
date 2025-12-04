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
    
    /// Findet automatisch das WiFi-Interface (en0, en1, etc.)
    /// - Returns: Der Interface-Name als String, oder `nil` wenn kein WiFi-Interface gefunden wurde
    func findWiFiInterface() -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/networksetup")
        process.arguments = ["-listallhardwareports"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            guard let output = String(data: data, encoding: .utf8) else {
                print("📡 WiFiManager: Konnte networksetup Output nicht lesen")
                return nil
            }
            
            // Parse Output: Suche nach "Wi-Fi" oder "AirPort" gefolgt von Interface-Name
            let lines = output.components(separatedBy: .newlines)
            var foundWiFi = false
            
            for line in lines {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                
                // Prüfe ob es eine Hardware-Port-Zeile ist
                if trimmed.contains("Wi-Fi") || trimmed.contains("AirPort") {
                    foundWiFi = true
                    continue
                }
                
                // Wenn wir WiFi gefunden haben, ist die nächste Zeile mit "Device:" das Interface
                if foundWiFi && trimmed.hasPrefix("Device:") {
                    let components = trimmed.components(separatedBy: ":")
                    if components.count >= 2 {
                        let interface = components[1].trimmingCharacters(in: .whitespaces)
                        print("📡 WiFiManager: WiFi-Interface gefunden: \(interface)")
                        return interface
                    }
                }
                
                // Reset wenn wir eine neue Hardware-Port-Sektion erreichen
                if trimmed.hasPrefix("Hardware Port:") && foundWiFi {
                    // Wir haben WiFi gefunden, aber kein Device gefunden - versuche weiter
                    foundWiFi = false
                }
            }
            
            print("📡 WiFiManager: Kein WiFi-Interface gefunden")
            return nil
            
        } catch {
            print("📡 WiFiManager: Fehler beim Ausführen von networksetup: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Ruft alle gespeicherten WLAN-Netzwerke aus macOS ab
    /// - Returns: Array von SSIDs (ohne Duplikate), oder leeres Array bei Fehlern
    func getAllSavedWiFiNetworks() -> [String] {
        // Finde zuerst das WiFi-Interface
        guard let interface = findWiFiInterface() else {
            print("📡 WiFiManager: Konnte WiFi-Interface nicht finden")
            return []
        }
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/networksetup")
        process.arguments = ["-listpreferredwirelessnetworks", interface]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            guard let output = String(data: data, encoding: .utf8) else {
                print("📡 WiFiManager: Konnte networksetup Output nicht lesen")
                return []
            }
            
            // Parse Output: Jede Zeile ist eine SSID (mit führenden Leerzeichen/Tabs)
            var ssids: [String] = []
            let lines = output.components(separatedBy: .newlines)
            
            for line in lines {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                
                // Überspringe leere Zeilen
                if trimmed.isEmpty {
                    continue
                }
                
                // Überspringe Header-Zeile (kann "Preferred networks:" oder "Preferred networks on en0:" sein)
                if trimmed.hasPrefix("Preferred networks") {
                    continue
                }
                
                // SSIDs haben führende Tabs/Leerzeichen - entferne diese
                let ssid = trimmed.trimmingCharacters(in: .whitespaces)
                
                // Entferne eventuelle Nummerierung (z.B. "1. SSID-Name")
                let cleanedSSID = ssid.replacingOccurrences(
                    of: "^\\d+\\.\\s*",
                    with: "",
                    options: .regularExpression
                ).trimmingCharacters(in: .whitespaces)
                
                if !cleanedSSID.isEmpty {
                    ssids.append(cleanedSSID)
                }
            }
            
            // Entferne Duplikate und sortiere
            let uniqueSSIDs = Array(Set(ssids)).sorted()
            print("📡 WiFiManager: \(uniqueSSIDs.count) gespeicherte WLANs gefunden")
            return uniqueSSIDs
            
        } catch {
            print("📡 WiFiManager: Fehler beim Abrufen gespeicherter WLANs: \(error.localizedDescription)")
            return []
        }
    }
}

