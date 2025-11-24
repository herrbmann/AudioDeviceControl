import SwiftUI
import AppKit

struct ProfileEditorPopoverView: View {
    let profile: Profile
    @Binding var isPresented: Bool
    @State private var editorWindow: NSWindow?
    
    var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .onAppear {
                openEditorWindow()
            }
            .onChange(of: isPresented) { oldValue, newValue in
                if !newValue {
                    editorWindow?.close()
                    editorWindow = nil
                }
            }
    }
    
    private func openEditorWindow() {
        DispatchQueue.main.async {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 800, height: 900),
                styleMask: [.titled, .closable, .resizable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            
            window.title = "Profil bearbeiten: \(profile.name)"
            window.center()
            window.setFrameAutosaveName("ProfileEditor")
            window.isReleasedWhenClosed = true
            window.level = .floating
            
            let hostingView = NSHostingView(rootView: ProfileEditorView(
                profile: profile,
                isPresented: Binding(
                    get: { true },
                    set: { if !$0 { 
                        window.close()
                        isPresented = false
                    } }
                ),
                window: window
            ))
            
            hostingView.frame = window.contentView!.bounds
            hostingView.autoresizingMask = [.width, .height]
            
            window.contentView = hostingView
            
            // Stelle sicher, dass die App aktiviert wird
            NSApp.setActivationPolicy(.regular)
            NSApp.activate(ignoringOtherApps: true)
            
            window.makeKeyAndOrderFront(nil)
            window.orderFrontRegardless()
            
            // Beobachte Fenster-Schließung
            NotificationCenter.default.addObserver(
                forName: NSWindow.willCloseNotification,
                object: window,
                queue: .main
            ) { _ in
                isPresented = false
                editorWindow = nil
            }
            
            editorWindow = window
        }
    }
}

