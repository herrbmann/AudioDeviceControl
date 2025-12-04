import Foundation
import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {
        // Request notification authorization on first use
        requestAuthorizationIfNeeded()
    }
    
    private func requestAuthorizationIfNeeded() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            if settings.authorizationStatus == .notDetermined {
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
                    if let error = error {
                        print("❌ NotificationManager: Authorization error: \(error)")
                    } else if granted {
                        print("✅ NotificationManager: Notification authorization granted")
                    } else {
                        print("⚠️ NotificationManager: Notification authorization denied")
                    }
                }
            }
        }
    }
    
    /// Sendet eine Notification bei automatischem Profil-Wechsel aufgrund von WiFi
    func notifyProfileSwitch(wifiSSID: String, profileName: String) {
        let content = UNMutableNotificationContent()
        content.title = "Profil gewechselt"
        content.body = "Verbunden mit Wi‑Fi \"\(wifiSSID)\"\nProfil gewechselt auf \"\(profileName)\""
        content.sound = .default
        
        // Erstelle Request mit sofortiger Auslieferung
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil // nil = sofortige Auslieferung
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ NotificationManager: Fehler beim Senden der Notification: \(error)")
            } else {
                print("✅ NotificationManager: Notification gesendet - WiFi: \(wifiSSID), Profil: \(profileName)")
            }
        }
    }
}

