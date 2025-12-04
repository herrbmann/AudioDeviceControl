import SwiftUI

struct DeletedDevicesView: View {
    @ObservedObject private var audioState = AudioState.shared
    @State private var inputDevices: [DeviceInfo] = []
    @State private var outputDevices: [DeviceInfo] = []
    
    struct DeviceInfo: Identifiable {
        let id: String // UID
        let name: String
        let isInput: Bool
        let isOutput: Bool
        let isCurrentlyConnected: Bool
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Alle Geräte")
                .font(.headline)
                .padding(.horizontal, 18)
                .padding(.top, 8)
            
            Text("Geräte, die du nicht mehr verwenden möchtest, können hier komplett aus dem Gedächtnis gelöscht werden. Sie erscheinen beim erneuten Anschließen wieder.")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 18)
                .padding(.bottom, 8)
            
            VStack(spacing: 8) {
                // Ausgabe-Geräte
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Spacer()
                        Text("Ausgabe-Geräte")
                            .font(.headline)
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 10)
                    .padding(.bottom, 2)
                    
                    if outputDevices.isEmpty {
                        Text("Keine Ausgabe-Geräte verfügbar")
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 12)
                    } else {
                        VStack(spacing: 6) {
                            ForEach(outputDevices) { deviceInfo in
                                deviceRow(deviceInfo)
                            }
                        }
                        .padding(.horizontal, 6)
                    }
                }
                .padding(.top, 8)
                
                Divider()
                    .padding(.horizontal, 12)
                    .padding(.vertical, 2)
                
                // Eingabe-Geräte
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Spacer()
                        Text("Eingabe-Geräte")
                            .font(.headline)
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 10)
                    .padding(.bottom, 2)
                    
                    if inputDevices.isEmpty {
                        Text("Keine Eingabe-Geräte verfügbar")
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 12)
                    } else {
                        VStack(spacing: 6) {
                            ForEach(inputDevices) { deviceInfo in
                                deviceRow(deviceInfo)
                            }
                        }
                        .padding(.horizontal, 6)
                    }
                }
                .padding(.top, 8)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 8)
        }
        .onAppear {
            loadAllDevices()
        }
        .onChange(of: audioState.listVersion) { _, _ in
            loadAllDevices()
        }
    }
    
    private func deviceRow(_ deviceInfo: DeviceInfo) -> some View {
        HStack(spacing: 10) {
            // Icon
            Image(nsImage: iconForDevice(deviceInfo))
                .resizable()
                .frame(width: 20, height: 20)
            
            // Name und Status
            VStack(alignment: .leading, spacing: 2) {
                Text(deviceInfo.name)
                    .font(.system(size: 13))
                
                if !deviceInfo.isCurrentlyConnected {
                    Text("Nicht verbunden")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Löschen-Button (X)
            Button {
                deleteDevice(deviceInfo)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
                    .font(.system(size: 14))
            }
            .buttonStyle(.borderless)
            .help("Komplett aus dem Gedächtnis löschen")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(NSColor.textBackgroundColor))
        .cornerRadius(5)
    }
    
    private func loadAllDevices() {
        var inputDevs: [DeviceInfo] = []
        var outputDevs: [DeviceInfo] = []
        let deletedUIDs = Set(PriorityStore.shared.loadDeletedUIDs())
        
        // Sammle alle bekannten Geräte (verbunden + offline aus Registry)
        // Verwende Sets um Duplikate zu vermeiden
        var processedInputUIDs = Set<String>()
        var processedOutputUIDs = Set<String>()
        
        // 1. Verbundene Input-Geräte hinzufügen (nur einmal pro UID, nicht gelöschte)
        for device in audioState.inputDevices {
            if !deletedUIDs.contains(device.persistentUID) && !processedInputUIDs.contains(device.persistentUID) {
                let deviceInfo = DeviceInfo(
                    id: device.persistentUID,
                    name: device.name,
                    isInput: device.isInput,
                    isOutput: device.isOutput,
                    isCurrentlyConnected: true
                )
                
                inputDevs.append(deviceInfo)
                processedInputUIDs.insert(device.persistentUID)
            }
        }
        
        // 2. Verbundene Output-Geräte hinzufügen (nur einmal pro UID, nicht gelöschte)
        for device in audioState.outputDevices {
            if !deletedUIDs.contains(device.persistentUID) && !processedOutputUIDs.contains(device.persistentUID) {
                let deviceInfo = DeviceInfo(
                    id: device.persistentUID,
                    name: device.name,
                    isInput: device.isInput,
                    isOutput: device.isOutput,
                    isCurrentlyConnected: true
                )
                
                outputDevs.append(deviceInfo)
                processedOutputUIDs.insert(device.persistentUID)
            }
        }
        
        // 3. Offline Geräte aus Registry hinzufügen (nur nicht-gelöschte und noch nicht verarbeitete)
        let knownUIDs = DeviceRegistry.shared.storedUIDs
        for uid in knownUIDs {
            if deletedUIDs.contains(uid) {
                continue // Gelöschte Geräte komplett überspringen
            }
            
            if let meta = DeviceRegistry.shared.metadata(for: uid) {
                let deviceInfo = DeviceInfo(
                    id: uid,
                    name: meta.name,
                    isInput: meta.isInput,
                    isOutput: meta.isOutput,
                    isCurrentlyConnected: false
                )
                
                // Nur hinzufügen, wenn noch nicht verarbeitet
                if meta.isInput && !processedInputUIDs.contains(uid) {
                    inputDevs.append(deviceInfo)
                    processedInputUIDs.insert(uid)
                }
                if meta.isOutput && !processedOutputUIDs.contains(uid) {
                    outputDevs.append(deviceInfo)
                    processedOutputUIDs.insert(uid)
                }
            }
        }
        
        // Sortiere alphabetisch
        inputDevs.sort { $0.name < $1.name }
        outputDevs.sort { $0.name < $1.name }
        
        inputDevices = inputDevs
        outputDevices = outputDevs
    }
    
    private func iconForDevice(_ deviceInfo: DeviceInfo) -> NSImage {
        func sym(_ name: String) -> NSImage {
            NSImage(systemSymbolName: name, accessibilityDescription: nil) ?? NSImage()
        }
        
        let lower = deviceInfo.name.lowercased()
        
        if deviceInfo.isOutput {
            if lower.contains("airpods") || lower.contains("headphone") || lower.contains("headset") {
                return sym("headphones")
            }
            if lower.contains("hifi") || lower.contains("hi-fi") || lower.contains("speaker") {
                return sym("speaker.wave.2.fill")
            }
            if lower.contains("display") || lower.contains("monitor") || lower.contains("hdmi") {
                return sym("display")
            }
            if lower.contains("tv") {
                return sym("tv")
            }
            return sym("speaker.wave.2.fill")
        }
        
        if deviceInfo.isInput {
            if lower.contains("airpods") || lower.contains("headset") || lower.contains("headphone") {
                return sym("headphones")
            }
            if lower.contains("built-in") || lower.contains("builtin") || lower.contains("internal") {
                return sym("mic.fill")
            }
            if lower.contains("usb") || lower.contains("mic") || lower.contains("microphone") {
                return sym("mic.fill")
            }
            return sym("mic.fill")
        }
        
        return sym("circle")
    }
    
    private func deleteDevice(_ deviceInfo: DeviceInfo) {
        // 1. Als gelöscht markieren
        PriorityStore.shared.addDeletedUID(deviceInfo.id)
        
        // 2. Aus allen Profilen entfernen
        removeFromAllProfiles(deviceInfo.id)
        
        // 3. Aus Registry entfernen
        DeviceRegistry.shared.removeDevice(deviceInfo.id)
        
        // Refresh
        audioState.refresh()
        loadAllDevices()
    }
    
    private func removeFromAllProfiles(_ uid: String) {
        let profileManager = ProfileManager.shared
        for profile in profileManager.profiles {
            var updatedProfile = profile
            updatedProfile.inputOrder.removeAll { $0 == uid }
            updatedProfile.outputOrder.removeAll { $0 == uid }
            // Entferne auch aus ignored Lists falls vorhanden
            updatedProfile.ignoredInputUIDs.removeAll { $0 == uid }
            updatedProfile.ignoredOutputUIDs.removeAll { $0 == uid }
            profileManager.updateProfile(updatedProfile)
        }
    }
}

