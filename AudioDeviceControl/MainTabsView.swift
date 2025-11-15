import SwiftUI
import AppKit
import ServiceManagement

enum LoginItemManager {
    static var isEnabled: Bool {
        switch SMAppService.mainApp.status {
        case .enabled: return true
        default: return false
        }
    }

    static func setEnabled(_ enabled: Bool) throws {
        if enabled {
            try SMAppService.mainApp.register()
        } else {
            try SMAppService.mainApp.unregister()
        }
    }
}

struct MainTabsView: View {

    @State private var selectedTab = 0
    @State private var launchAtLogin = false
    @State private var errorMessage: String?
    @State private var showQuitConfirm = false

    var body: some View {
        VStack(spacing: 12) {

            // ✳️ App Title ganz oben
            Text("AudioDeviceControl")
                .font(.title3)
                .bold()
                .padding(.top, 8)

            Divider()
                .padding(.horizontal, 12)

            // ✳️ Tabs darunter
            Picker("", selection: $selectedTab) {
                Text("Output").tag(0)
                Text("Input").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 20)
            
            // Removed Launch at Login Toggle here

            // ✳️ Content
            Group {
                if selectedTab == 0 {
                    OutputDevicesView()
                } else {
                    InputDevicesView()
                }
            }
            .padding(.top, 4)

            // ✳️ Tutorial / Short Description
            VStack(spacing: 8) {

                Text("Drag & drop to set your preferred priority.")
                    .font(.callout)
                    .foregroundColor(.secondary)

                Text("AudioDeviceControl automatically selects the highest available device.")
                    .font(.callout)
                    .foregroundColor(.secondary)

                // Farbcode-Erklärung – mit farbigen Kreisen
                VStack(spacing: 4) {
                    HStack(spacing: 6) {
                        Text("●")
                            .foregroundColor(.green)
                        Text("Green = Active device")
                    }
                    HStack(spacing: 6) {
                        Text("●")
                            .foregroundColor(.blue)
                        Text("Blue = Connected but not active")
                    }
                    HStack(spacing: 6) {
                        Text("●")
                            .foregroundColor(.gray)
                        Text("Gray = Offline or not available")
                    }
                }
                .font(.callout)
                .foregroundColor(.secondary)
                .padding(.top, 4)

                // Welche Geräte angezeigt werden
                Text("Only real input/output audio devices are shown — virtual routing devices are hidden to keep this list clean.")
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 18)
            .padding(.top, 6)

            // ✳️ Start app on login section (own separators)
            Divider()
                .padding(.horizontal, 18)
                .padding(.top, 6)

            HStack {
                Spacer(minLength: 0)
                Toggle("start app on login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { oldValue, newValue in
                        do {
                            try LoginItemManager.setEnabled(newValue)
                            // Sync with actual system status
                            launchAtLogin = LoginItemManager.isEnabled
                        } catch {
                            // Rollback on error and show message
                            launchAtLogin.toggle()
                            errorMessage = error.localizedDescription
                        }
                    }
                    .toggleStyle(.checkbox)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 6)

            Divider()
                .padding(.horizontal, 18)

            VStack(spacing: 4) {
                Text("Got feedback or an idea for a great new feature?")
                    .font(.callout)
                    .foregroundColor(.secondary)

                if let url = URL(string: "mailto:audiocontrol@techbude.com") {
                    Link("audiocontrol@techbude.com", destination: url)
                        .font(.callout)
                } else {
                    Text("audiocontrol@techbude.com")
                        .font(.callout)
                        .foregroundColor(.secondary)
                }
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 18)

            // ✳️ Footer-Credit
            Divider()
                .padding(.horizontal, 18)
                .padding(.top, 6)

            Text("made without a clue by techbude")
                .font(.footnote)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Spacer(minLength: 8)

            // ✳️ Bottom Buttons: Beenden (links) & Close (rechts)
            HStack {
                Button("Quit App") {
                    showQuitConfirm = true
                }
                .buttonStyle(.bordered)

                Spacer(minLength: 12)

                Button("Close") {
                    // Close the popover via notification to StatusBarController
                    NotificationCenter.default.post(name: .closePopoverRequested, object: nil)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            launchAtLogin = LoginItemManager.isEnabled
        }
        .alert("Couldn't update Login Item", isPresented: .constant(errorMessage != nil)) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
        .alert("App wirklich beenden?", isPresented: $showQuitConfirm) {
            Button("Abbrechen", role: .cancel) {}
            Button("Jetzt beenden", role: .destructive) {
                NSApp.terminate(nil)
            }
        } message: {
            Text("Möchtest du AudioDeviceControl jetzt beenden?")
        }
    }
}

