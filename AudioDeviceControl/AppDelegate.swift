import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarController: StatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize ProfileManager early to perform migration if needed
        _ = ProfileManager.shared
        
        statusBarController = StatusBarController()
        _ = DeviceWatcher.shared
        _ = WiFiWatcher.shared
        NSApp.setActivationPolicy(.accessory)
        
        // Request Location Services permission for WiFi detection
        WiFiManager.shared.requestLocationPermission()
        
        // Check for updates on launch (if enabled and not checked recently)
        UpdateChecker.shared.checkForUpdates()
    }
}
