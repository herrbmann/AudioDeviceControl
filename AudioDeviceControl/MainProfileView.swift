import SwiftUI
import AppKit
import ServiceManagement
import Foundation

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

struct MainProfileView: View {
    
    @State private var showQuitConfirm = false
    @State private var editingProfile: Profile?
    @State private var showProfileEditor = false
    @State private var showDeleteConfirm = false
    @State private var profileToDelete: Profile?
    @State private var launchAtLogin = false
    @State private var updateCheckEnabled = true
    @State private var errorMessage: String?
    @ObservedObject private var profileManager = ProfileManager.shared
    @ObservedObject private var audioState = AudioState.shared
    @ObservedObject private var updateChecker = UpdateChecker.shared
    
    var body: some View {
        VStack(spacing: 12) {
            
            // App Title
            Text("AudioDeviceControl")
                .font(.title3)
                .bold()
                .padding(.top, 8)
            
            Divider()
                .padding(.horizontal, 18)
            
            // Profile Content (scrollbar nur für Profile)
            ProfileTabView(
                editingProfile: $editingProfile,
                showProfileEditor: $showProfileEditor,
                showDeleteConfirm: $showDeleteConfirm,
                profileToDelete: $profileToDelete
            )
            .frame(maxWidth: .infinity)
            
            // Tutorial / Short Description (statisch)
            VStack(spacing: 8) {
                Text("Profile ermöglichen verschiedene Audio-Konfigurationen für verschiedene Situationen.")
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 18)
            .padding(.top, 6)
            
            Divider()
                .padding(.horizontal, 18)
            
            // Buy me a coffee (statisch)
            VStack(spacing: 8) {
                Text("Like my app? Feel free to")
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
                            Text("Buy me a coffee")
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
                        Toggle("Start app on login", isOn: $launchAtLogin)
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
                        Toggle("Automatically check for updates", isOn: $updateCheckEnabled)
                            .onChange(of: updateCheckEnabled) { _, newValue in
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
            
            // Bottom Buttons
            HStack {
                Button("Quit App") {
                    showQuitConfirm = true
                }
                .buttonStyle(.bordered)
                
                Spacer(minLength: 12)
                
                Button("Close") {
                    NotificationCenter.default.post(name: .closePopoverRequested, object: nil)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            Group {
                if showProfileEditor, let profile = editingProfile {
                    ProfileEditorPopoverView(
                        profile: profile,
                        isPresented: $showProfileEditor
                    )
                } else {
                    Color.clear
                }
            }
        )
        .alert("Profil löschen?", isPresented: $showDeleteConfirm) {
            Button("Abbrechen", role: .cancel) {
                profileToDelete = nil
            }
            Button("Löschen", role: .destructive) {
                if let profile = profileToDelete {
                    profileManager.deleteProfile(profile)
                    profileToDelete = nil
                }
            }
        } message: {
            if let profile = profileToDelete {
                Text("Möchtest du das Profil \"\(profile.name)\" wirklich löschen? Diese Aktion kann nicht rückgängig gemacht werden.")
            }
        }
        .alert("App wirklich beenden?", isPresented: $showQuitConfirm) {
            Button("Abbrechen", role: .cancel) {}
            Button("Jetzt beenden", role: .destructive) {
                NSApp.terminate(nil)
            }
        } message: {
            Text("Möchtest du AudioDeviceControl jetzt beenden?")
        }
        .alert("Couldn't update Login Item", isPresented: .constant(errorMessage != nil)) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
        .onAppear {
            launchAtLogin = LoginItemManager.isEnabled
            updateCheckEnabled = UpdateStore.shared.isUpdateCheckEnabled()
        }
    }
    
    private func openProfileEditor(profile: Profile) {
        editingProfile = profile
        showProfileEditor = true
    }
}

struct ProfileTabView: View {
    @Binding var editingProfile: Profile?
    @Binding var showProfileEditor: Bool
    @Binding var showDeleteConfirm: Bool
    @Binding var profileToDelete: Profile?
    @ObservedObject private var profileManager = ProfileManager.shared
    @ObservedObject private var audioState = AudioState.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // Scrollbare Profil-Liste
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(profileManager.profiles) { profile in
                        ProfileCardView(
                            profile: profile,
                            isActive: profileManager.activeProfile?.id == profile.id,
                            onActivate: {
                                profileManager.setActiveProfile(profile)
                                audioState.switchToProfile(profile)
                            },
                            onEdit: {
                                editingProfile = profile
                                showProfileEditor = true
                            },
                            onDelete: {
                                profileToDelete = profile
                                showDeleteConfirm = true
                            }
                        )
                    }
                    
                    // Neues Profil Button
                    Button {
                        let newProfile = profileManager.createProfile(
                            name: "Neues Profil",
                            icon: "🎧",
                            color: ProfileColorPreset.colors[0].hex
                        )
                        editingProfile = newProfile
                        showProfileEditor = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Neues Profil")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .padding(.bottom, 12)
            }
            .frame(height: 400) // Feste Höhe für mindestens 4 Profile + Button
            
            Divider()
                .padding(.horizontal, 18)
            
            // Status-Info (statisch)
            if let activeProfile = profileManager.activeProfile {
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Text("Aktives Profil:")
                            .font(.headline)
                        Text(activeProfile.icon + " " + activeProfile.name)
                            .font(.headline)
                            .foregroundColor(Color(hex: activeProfile.color))
                    }
                    
                    if let activeInput = audioState.inputDevices.first(where: { $0.state == .active }) {
                        HStack(spacing: 6) {
                            Text("Input:")
                                .foregroundColor(.secondary)
                            Text(activeInput.name)
                                .foregroundColor(.primary)
                        }
                        .font(.callout)
                    }
                    
                    if let activeOutput = audioState.outputDevices.first(where: { $0.state == .active }) {
                        HStack(spacing: 6) {
                            Text("Output:")
                                .foregroundColor(.secondary)
                            Text(activeOutput.name)
                                .foregroundColor(.primary)
                        }
                        .font(.callout)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
            }
        }
    }
}

struct ProfileCardView: View {
    let profile: Profile
    let isActive: Bool
    let onActivate: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Emoji
            Text(profile.icon)
                .font(.system(size: 32))
            
            // Name
            Text(profile.name)
                .font(.headline)
                .foregroundColor(.primary)
            
            Spacer()
            
            // Buttons
            HStack(spacing: 8) {
                Button {
                    print("🔧 ProfileCardView: Edit button tapped")
                    onEdit()
                } label: {
                    Image(systemName: "pencil")
                }
                .buttonStyle(.bordered)
                .help("Bearbeiten")
                
                Button {
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.bordered)
                .help("Löschen")
                .foregroundColor(.red)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(hex: profile.color).opacity(0.2))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(
                    isActive ? Color(hex: profile.color) : Color.clear,
                    lineWidth: 2
                )
        )
        .contentShape(Rectangle())
        .onTapGesture {
            if !isActive {
                onActivate()
            }
        }
    }
}

