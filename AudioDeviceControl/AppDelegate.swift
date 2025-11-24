import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarController: StatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize ProfileManager early to perform migration if needed
        _ = ProfileManager.shared
        
        statusBarController = StatusBarController()
        _ = DeviceWatcher.shared
        NSApp.setActivationPolicy(.accessory)
        
        // Check for updates on launch (if enabled and not checked recently)
        UpdateChecker.shared.checkForUpdates()
    }
}
