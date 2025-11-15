import Cocoa
import SwiftUI

class StatusBarController {

    private var statusItem: NSStatusItem
    private let popover: NSPopover = NSPopover()

    init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            // 🎧 Kopfhörer-Icon (Template → automatisch hell/dunkel angepasst)
            button.image = NSImage(systemSymbolName: "headphones", accessibilityDescription: nil)
            button.image?.isTemplate = true

            button.target = self
            button.action = #selector(togglePopover)
        }

        // Configure popover with SwiftUI content
        popover.behavior = .transient
        popover.contentSize = NSSize(width: 520, height: 640)
        popover.contentViewController = NSHostingController(rootView: MainTabsView())

        NotificationCenter.default.addObserver(self, selector: #selector(closePopover), name: .closePopoverRequested, object: nil)
    }

    @objc private func togglePopover() {
        if popover.isShown {
            popover.performClose(nil)
        } else {
            showPopover()
        }
    }

    private func showPopover() {
        guard let button = statusItem.button else { return }
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .maxY)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func closePopover() {
        if popover.isShown {
            popover.performClose(nil)
        }
    }
}

extension Notification.Name {
    static let closePopoverRequested = Notification.Name("closePopoverRequested")
}
