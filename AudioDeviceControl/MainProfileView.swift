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
    
    @State private var showSettings = false
    @State private var showQuitConfirm = false
    @State private var editingProfile: Profile?
    @State private var showProfileEditor = false
    @State private var showDeleteConfirm = false
    @State private var profileToDelete: Profile?
    @ObservedObject private var profileManager = ProfileManager.shared
    @ObservedObject private var audioState = AudioState.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // App Title - ganz oben
            VStack(spacing: 0) {
                Text("AudioDeviceControl")
                    .font(.title3)
                    .bold()
                    .padding(.top, 12)
                    .padding(.bottom, 8)
                
                Divider()
            }
            .onReceive(NotificationCenter.default.publisher(for: .showSettingsRequested)) { _ in
                showSettings = true
            }
            
            // Content - nimmt verfügbaren Platz
            Group {
                if showSettings {
                    SettingsView()
                } else {
                    // Profile Content oder Editor
                    if showProfileEditor, let profile = editingProfile {
                        ProfileEditorView(
                            profile: profile,
                            isPresented: $showProfileEditor,
                            showSettings: $showSettings
                        )
                    } else {
                        ProfileTabView(
                            editingProfile: $editingProfile,
                            showProfileEditor: $showProfileEditor,
                            showDeleteConfirm: $showDeleteConfirm,
                            profileToDelete: $profileToDelete
                        )
                    }
                }
            }
            .frame(maxWidth: .infinity, minHeight: 200)
            
            // Bottom Buttons - ganz unten
            VStack(spacing: 0) {
                Divider()
                
                HStack {
                    Button("Quit App") {
                        showQuitConfirm = true
                    }
                    .buttonStyle(.bordered)
                    
                    Spacer(minLength: 12)
                    
                    Button(showSettings ? "Zurück" : "Settings") {
                        showSettings.toggle()
                    }
                    .buttonStyle(.bordered)
                    
                    Spacer(minLength: 12)
                    
                    Button("Close") {
                        NotificationCenter.default.post(name: .closePopoverRequested, object: nil)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .padding(.bottom, 12)
            }
        }
        .frame(minWidth: 520, maxWidth: 520)
        .background(Color(NSColor.windowBackgroundColor))
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

