import SwiftUI
import AppKit
import ServiceManagement
import Foundation

struct SettingsView: View {
    @State private var launchAtLogin = false
    @State private var updateCheckEnabled = true
    @State private var wifiAutoSwitchEnabled = false
    @State private var errorMessage: String?
    @ObservedObject private var updateChecker = UpdateChecker.shared
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 12) {
                    // Buy me a coffee
                    VStack(spacing: 8) {
                        Text("Gefällt dir die App? Dann")
                            .font(.callout)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Spacer(minLength: 0)
                            Button {
                                if let url = URL(string: "https://ko-fi.com/X7X01OMYL7") {
                                    NSWorkspace.shared.open(url)
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "cup.and.saucer")
                                        .imageScale(.small)
                                    Text("Kauf mir einen Kaffee")
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                            }
                            .buttonStyle(.bordered)
                            .tint(Color(red: 180/255, green: 115/255, blue: 245/255))
                            Spacer(minLength: 0)
                        }
                    }
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 18)
                    .padding(.top, 8)
                    
                    Divider()
                        .padding(.horizontal, 18)
                    
                    // Allgemein Settings
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Allgemein")
                            .font(.headline)
                            .padding(.horizontal, 18)
                            .padding(.top, 8)
                        
                        VStack(spacing: 8) {
                            HStack {
                                Spacer(minLength: 0)
                                Toggle("App beim Anmelden starten", isOn: $launchAtLogin)
                                    .onChange(of: launchAtLogin) { _, newValue in
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
                                Toggle("Automatisch nach Updates suchen", isOn: $updateCheckEnabled)
                                    .onChange(of: updateCheckEnabled) { _, newValue in
                                        UpdateStore.shared.setUpdateCheckEnabled(newValue)
                                    }
                                    .toggleStyle(.checkbox)
                                Spacer(minLength: 0)
                            }
                            
                            HStack {
                                Spacer(minLength: 0)
                                Toggle("Automatischer Profilwechsel per WiFi", isOn: $wifiAutoSwitchEnabled)
                                    .onChange(of: wifiAutoSwitchEnabled) { _, newValue in
                                        WiFiStore.shared.setWiFiAutoSwitchEnabled(newValue)
                                        WiFiWatcher.shared.updateEnabledState()
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
                    
                    // App Info
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
                    
                    Text("built just for fun, by the guys from OB7")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)
                }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .alert("Login-Element konnte nicht aktualisiert werden", isPresented: .constant(errorMessage != nil)) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
        .onAppear {
            launchAtLogin = LoginItemManager.isEnabled
            updateCheckEnabled = UpdateStore.shared.isUpdateCheckEnabled()
            wifiAutoSwitchEnabled = WiFiStore.shared.isWiFiAutoSwitchEnabled()
        }
    }
}
