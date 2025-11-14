import Cocoa
import SwiftUI

class StatusBarController {

    private let statusItem: NSStatusItem
    private var windowController: NSWindowController?

    init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "waveform.circle", accessibilityDescription: nil)
            button.image?.isTemplate = true
            button.target = self
            button.action = #selector(toggleWindow)
        }
    }

    @objc private func toggleWindow() {
        if let wc = windowController, wc.window?.isVisible == true {
            animateClose(wc.window!)
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

        // Immer im Vordergrund
        window.level = .floating                // <- bleibt über allen Fenstern
        window.collectionBehavior = [.canJoinAllSpaces]

        // Titelbar verstecken
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.standardWindowButton(.closeButton)?.isHidden = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true

        window.isMovableByWindowBackground = true
        window.isReleasedWhenClosed = false
        window.alphaValue = 0          // Start: unsichtbar
        window.contentView = hosting.view
        hosting.view.frame = window.contentView!.bounds

        // Position unter der Menübar
        if let button = statusItem.button,
           let frame = button.window?.convertToScreen(button.frame)
        {
            let x = frame.midX - (windowWidth / 2)
            let y = frame.minY - windowHeight - 4
            window.setFrameOrigin(NSPoint(x: x, y: y))
        }

        let wc = NSWindowController(window: window)
        windowController = wc
        wc.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)

        animateOpen(window)
    }

    // MARK: - Animationen

    private func animateOpen(_ window: NSWindow) {
        window.alphaValue = 0
        let originalY = window.frame.origin.y

        // leicht von oben nach unten sliden
        window.setFrameOrigin(NSPoint(x: window.frame.origin.x,
                                      y: originalY + 8))

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.18
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)

            window.animator().alphaValue = 1.0
            window.animator().setFrameOrigin(NSPoint(
                x: window.frame.origin.x,
                y: originalY
            ))
        }
    }

    private func animateClose(_ window: NSWindow) {
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.15
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)

            window.animator().alphaValue = 0
            window.animator().setFrameOrigin(NSPoint(
                x: window.frame.origin.x,
                y: window.frame.origin.y + 6
            ))
        }, completionHandler: {
            window.close()
        })
    }
}
