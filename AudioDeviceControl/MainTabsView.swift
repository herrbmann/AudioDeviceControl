import SwiftUI
import AppKit
import ServiceManagement
import Foundation

struct MainTabsView: View {

    @State private var selectedTab = 0
    @State private var launchAtLogin = false
    @State private var updateCheckEnabled = true
    @State private var errorMessage: String?
    @State private var showQuitConfirm = false
    @ObservedObject private var audioState = AudioState.shared
    @ObservedObject private var updateChecker = UpdateChecker.shared

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
                Text("Ausgabe").tag(0)
                Text("Eingabe").tag(1)
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

                Text("Per Drag & Drop kannst du deine bevorzugte Priorität festlegen.")
                    .font(.callout)
                    .foregroundColor(.secondary)

                Text("AudioDeviceControl wählt automatisch das höchste verfügbare Gerät aus.")
                    .font(.callout)
                    .foregroundColor(.secondary)

                // Farbcode-Erklärung – mit farbigen Kreisen
                VStack(spacing: 4) {
                    HStack(spacing: 6) {
                        Text("●")
                            .foregroundColor(.green)
                        Text("Grün = Aktives Gerät")
                    }
                    HStack(spacing: 6) {
                        Text("●")
                            .foregroundColor(.blue)
                        Text("Blau = Verbunden, aber nicht aktiv")
                    }
                    HStack(spacing: 6) {
                        Text("●")
                            .foregroundColor(.gray)
                        Text("Grau = Offline oder nicht verfügbar")
                    }
                }
                .font(.callout)
                .foregroundColor(.secondary)
                .padding(.top, 4)

                // Welche Geräte angezeigt werden
                Text("Nur echte Eingabe-/Ausgabe-Audiogeräte werden angezeigt — virtuelle Routing-Geräte sind ausgeblendet, um die Liste übersichtlich zu halten.")
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 4)
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 18)
            .padding(.top, 6)

            // ✳️ Start app on login section (own separators)
            Divider()
                .padding(.horizontal, 18)
                .padding(.top, 6)

            VStack(spacing: 8) {
                HStack {
                    Spacer(minLength: 0)
                    Toggle("App beim Anmelden starten", isOn: $launchAtLogin)
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
                
                HStack {
                    Spacer(minLength: 0)
                    Toggle("Automatisch nach Updates suchen", isOn: $updateCheckEnabled)
                        .onChange(of: updateCheckEnabled) { oldValue, newValue in
                            UpdateStore.shared.setUpdateCheckEnabled(newValue)
                        }
                        .toggleStyle(.checkbox)
                    Spacer(minLength: 0)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 6)

            Divider()
                .padding(.horizontal, 18)

            VStack(spacing: 8) {
                Text("Gefällt dir die App? Dann")
                    .font(.callout)
                    .foregroundColor(.secondary)

                // Buy me a coffee (in feedback section)
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
                    .tint(Color(red: 180/255, green: 115/255, blue: 245/255)) // #b473f5
                    Spacer(minLength: 0)
                }
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 18)

            // ✳️ Footer-Credit
            Divider()
                .padding(.horizontal, 18)
                .padding(.top, 6)

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

            Spacer(minLength: 8)

            // ✳️ Bottom Buttons: Beenden (links) & Close (rechts)
            HStack {
                Button("App beenden") {
                    showQuitConfirm = true
                }
                .buttonStyle(.bordered)

                Spacer(minLength: 12)

                Button("Schließen") {
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
            updateCheckEnabled = UpdateStore.shared.isUpdateCheckEnabled()
        }
        .alert("Login-Element konnte nicht aktualisiert werden", isPresented: .constant(errorMessage != nil)) {
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
