import SwiftUI
import AppKit

struct SettingsView: View {
    @State private var launchAtLogin = false
    @State private var updateCheckEnabled = true
    @State private var errorMessage: String?
    @ObservedObject private var audioState = AudioState.shared
    @ObservedObject private var updateChecker = UpdateChecker.shared
    @ObservedObject private var profileManager = ProfileManager.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Launch at Login
                VStack(alignment: .leading, spacing: 12) {
                    Text("Allgemein")
                        .font(.headline)
                        .padding(.horizontal, 18)
                        .padding(.top, 12)
                    
                    VStack(spacing: 8) {
                        HStack {
                            Spacer(minLength: 0)
                            Toggle("Start app on login", isOn: $launchAtLogin)
                                .onChange(of: launchAtLogin) { oldValue, newValue in
                                    do {
                                        try LoginItemManager.setEnabled(newValue)
                                        launchAtLogin = LoginItemManager.isEnabled
                                    } catch {
                                        launchAtLogin.toggle()
                                        errorMessage = error.localizedDescription
                                    }
                                }
                                .toggleStyle(.checkbox)
                            Spacer(minLength: 0)
                        }
                        
                        HStack {
                            Spacer(minLength: 0)
                            Toggle("Automatically check for updates", isOn: $updateCheckEnabled)
                                .onChange(of: updateCheckEnabled) { oldValue, newValue in
                                    UpdateStore.shared.setUpdateCheckEnabled(newValue)
                                }
                                .toggleStyle(.checkbox)
                            Spacer(minLength: 0)
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 8)
                }
                
                Divider()
                    .padding(.horizontal, 18)
                
                VStack(spacing: 4) {
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
                
                // Update Status
                if case .updateAvailable(let info) = updateChecker.updateStatus {
                    VStack(spacing: 6) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.down.circle.fill")
                                .foregroundColor(.orange)
                            Text("Update verfügbar: Version \(info.latestVersion)")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                        Button {
                            updateChecker.openReleasePage()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.down.circle")
                                Text("Jetzt updaten")
                            }
                            .font(.footnote)
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.top, 4)
                }
                
                // App Version
                if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                    HStack(spacing: 8) {
                        Text("Version \(version)")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        
                        if updateChecker.isChecking {
                            ProgressView()
                                .scaleEffect(0.6)
                        } else {
                            Button {
                                updateChecker.checkForUpdates(force: true)
                            } label: {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 10))
                            }
                            .buttonStyle(.borderless)
                            .help("Jetzt nach Updates prüfen")
                        }
                    }
                }
                
                Text("made without a clue by techbude")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
            }
            .padding(.bottom, 20)
        }
        .onAppear {
            launchAtLogin = LoginItemManager.isEnabled
            updateCheckEnabled = UpdateStore.shared.isUpdateCheckEnabled()
        }
        .alert("Couldn't update Login Item", isPresented: .constant(errorMessage != nil)) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }
}

