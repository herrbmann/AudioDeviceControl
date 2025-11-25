import Cocoa
import SwiftUI

class StatusBarController {

    private var statusItem: NSStatusItem
    private let popover: NSPopover = NSPopover()

    init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            // Waveform Icon (Template → automatisch hell/dunkel angepasst)
            button.image = NSImage(named: "StatusBarIcon")
            button.image?.isTemplate = true

            button.target = self
            button.action = #selector(togglePopover)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        // Configure popover with SwiftUI content
        popover.behavior = .transient
        popover.contentSize = NSSize(width: 520, height: 800)
        popover.contentViewController = NSHostingController(rootView: MainProfileView())

        NotificationCenter.default.addObserver(self, selector: #selector(closePopover), name: .closePopoverRequested, object: nil)
    }

    @objc private func togglePopover() {
        guard let event = NSApp.currentEvent else { return }
        
        if event.type == .rightMouseUp {
            // Rechtsklick: Zeige Profil-Menü
            showProfileMenu()
        } else {
            // Linksklick: Toggle Popover
            if popover.isShown {
                popover.performClose(nil)
            } else {
                showPopover()
            }
        }
    }
    
    private func showProfileMenu() {
        let menu = NSMenu()
        let profileManager = ProfileManager.shared
        let audioState = AudioState.shared
        
        // Aktuelles Profil anzeigen
        if let activeProfile = profileManager.activeProfile {
            let titleItem = NSMenuItem(title: "Aktives Profil: \(activeProfile.icon) \(activeProfile.name)", action: nil, keyEquivalent: "")
            titleItem.isEnabled = false
            menu.addItem(titleItem)
            menu.addItem(NSMenuItem.separator())
        }
        
        // Profil-Wechsel
        menu.addItem(NSMenuItem(title: "Profile wechseln:", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        
        for profile in profileManager.profiles {
            let isActive = profileManager.activeProfile?.id == profile.id
            let menuItem = NSMenuItem(
                title: "\(profile.icon) \(profile.name)",
                action: #selector(switchToProfile(_:)),
                keyEquivalent: ""
            )
            menuItem.representedObject = profile.id.uuidString
            menuItem.state = isActive ? .on : .off
            menu.addItem(menuItem)
        }
        
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Einstellungen öffnen", action: #selector(openSettings), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Beenden", action: #selector(quitApp), keyEquivalent: ""))
        
        if let button = statusItem.button {
            menu.popUp(positioning: nil, at: NSPoint(x: 0, y: button.bounds.height), in: button)
        }
    }
    
    @objc private func switchToProfile(_ sender: NSMenuItem) {
        guard let uuidString = sender.representedObject as? String,
              let uuid = UUID(uuidString: uuidString),
              let profile = ProfileManager.shared.getProfile(by: uuid) else {
            return
        }
        
        ProfileManager.shared.setActiveProfile(profile)
        AudioState.shared.switchToProfile(profile)
    }
    
    @objc private func openSettings() {
        if !popover.isShown {
            showPopover()
        }
    }
    
    @objc private func quitApp() {
        NSApp.terminate(nil)
    }

    private func showPopover() {
        guard let button = statusItem.button else { return }
        // Show popover without changing activation policy (keeps menu bar only)
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .maxY)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func closePopover() {
        if popover.isShown {
            popover.performClose(nil)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

extension Notification.Name {
    static let closePopoverRequested = Notification.Name("closePopoverRequested")
}
