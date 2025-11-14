import Cocoa
import SwiftUI

class StatusBarController {

    private var statusItem: NSStatusItem
    private var windowController: NSWindowController?

    init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            // 🎧 Kopfhörer-Icon (Template → automatisch hell/dunkel angepasst)
            button.image = NSImage(systemSymbolName: "headphones", accessibilityDescription: nil)
            button.image?.isTemplate = true

            button.target = self
            button.action = #selector(toggleWindow)
        }
    }

    @objc private func toggleWindow() {
        if let wc = windowController, wc.window?.isVisible == true {
            wc.close()
        } else {
            openWindowUnderStatusItem()
        }
    }

    private func openWindowUnderStatusItem() {

        let content = MainTabsView()
        let hosting = NSHostingController(rootView: content)

        let windowWidth: CGFloat = 480
        let windowHeight: CGFloat = 480

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: windowWidth, height: windowHeight),
            styleMask: [.titled],
            backing: .buffered,
            defer: false
        )

        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true

        window.standardWindowButton(.closeButton)?.isHidden = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true

        window.isMovableByWindowBackground = true
        window.isReleasedWhenClosed = false
        window.contentView = hosting.view

        if let button = statusItem.button {
            let buttonFrame = button.window?.convertToScreen(button.frame) ?? .zero

            let x = buttonFrame.midX - windowWidth / 2
            let y = buttonFrame.minY - windowHeight - 4

            window.setFrameOrigin(NSPoint(x: x, y: y))
        }

        let wc = NSWindowController(window: window)
        windowController = wc
        wc.showWindow(nil)

        NSApp.activate(ignoringOtherApps: true)
    }
}
