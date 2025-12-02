import SwiftUI
import AppKit

struct IgnoreDevicesView: View {
    @State private var inputDevices: [AudioDevice] = []
    @State private var outputDevices: [AudioDevice] = []
    @State private var ignoredUIDs: Set<String> = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ignore Devices")
                .font(.headline)
                .padding(.horizontal, 18)
                .padding(.top, 8)
            
            Text("Geräte, die hier markiert sind, werden in allen Profilen ignoriert und nicht angezeigt.")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 18)
            
            // Output Devices Sektion (zuerst)
            VStack(alignment: .leading, spacing: 8) {
                Text("Output Devices")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 18)
                    .padding(.top, 8)
                
                if outputDevices.isEmpty {
                    Text("Keine Output-Geräte gefunden")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 8)
                } else {
                    IgnoreDeviceList(
                        devices: outputDevices,
                        ignoredUIDs: ignoredUIDs,
                        onToggle: { device in
                            toggleIgnore(device: device)
                        },
                        onForget: { device in
                            forgetDevice(device: device)
                        }
                    )
                    .padding(.horizontal, 18)
                }
            }
            
            Divider()
                .padding(.horizontal, 18)
                .padding(.vertical, 4)
            
            // Input Devices Sektion (danach)
            VStack(alignment: .leading, spacing: 8) {
                Text("Input Devices")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 18)
                    .padding(.top, 8)
                
                if inputDevices.isEmpty {
                    Text("Keine Input-Geräte gefunden")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 8)
                } else {
                    IgnoreDeviceList(
                        devices: inputDevices,
                        ignoredUIDs: ignoredUIDs,
                        onToggle: { device in
                            toggleIgnore(device: device)
                        },
                        onForget: { device in
                            forgetDevice(device: device)
                        }
                    )
                    .padding(.horizontal, 18)
                }
            }
            
            Divider()
                .padding(.horizontal, 18)
                .padding(.vertical, 4)
            
            // Reset Button
            HStack {
                Spacer()
                Button {
                    resetAllIgnored()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Alle zurücksetzen")
                    }
                }
                .buttonStyle(.bordered)
                .disabled(ignoredUIDs.isEmpty)
                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 8)
        }
        .onAppear {
            loadDevices()
            loadIgnoredUIDs()
        }
    }
    
    private func loadDevices() {
        let ids = AudioDeviceManager.shared.getAllDeviceIDs()
        let defaultInputID = AudioDeviceManager.shared.getDefaultInputDevice()
        let defaultOutputID = AudioDeviceManager.shared.getDefaultOutputDevice()
        
        var inputs: [AudioDevice] = []
        var outputs: [AudioDevice] = []
        var inputUIDs = Set<String>()
        var outputUIDs = Set<String>()
        
        // Lade alle aktuell verbundenen Geräte
        for id in ids {
            let isInput = AudioDeviceManager.shared.isInputDevice(id)
            let isOutput = AudioDeviceManager.shared.isOutputDevice(id)
            
            guard let device = AudioDeviceFactory.make(
                from: id,
                isInput: isInput,
                isOutput: isOutput,
                defaultInputID: defaultInputID,
                defaultOutputID: defaultOutputID
            ) else { continue }
            
            if isInput {
                inputs.append(device)
                inputUIDs.insert(device.persistentUID)
            }
            if isOutput {
                outputs.append(device)
                outputUIDs.insert(device.persistentUID)
            }
        }
        
        // Register devices
        DeviceRegistry.shared.registerDevices(inputs + outputs)
        
        // Lade alle bekannten Geräte aus dem Registry (auch offline)
        let knownUIDs = DeviceRegistry.shared.storedUIDs
        for uid in knownUIDs {
            // Überspringe bereits geladene Geräte
            if inputUIDs.contains(uid) || outputUIDs.contains(uid) {
                continue
            }
            
            // Lade Metadaten für offline Geräte
            if let meta = DeviceRegistry.shared.metadata(for: uid) {
                let offlineDevice = AudioDeviceFactory.makeOffline(
                    uid: uid,
                    name: meta.name,
                    isInput: meta.isInput,
                    isOutput: meta.isOutput
                )
                
                if meta.isInput {
                    inputs.append(offlineDevice)
                }
                if meta.isOutput {
                    outputs.append(offlineDevice)
                }
            }
        }
        
        // Sortiere nach Name
        inputDevices = inputs.sorted { $0.name < $1.name }
        outputDevices = outputs.sorted { $0.name < $1.name }
    }
    
    private func loadIgnoredUIDs() {
        ignoredUIDs = Set(PriorityStore.shared.loadIgnoredUIDs())
    }
    
    private func toggleIgnore(device: AudioDevice) {
        let isCurrentlyIgnored = ignoredUIDs.contains(device.persistentUID)
        
        if isCurrentlyIgnored {
            // Entferne aus Ignore-Liste
            PriorityStore.shared.removeIgnoredUID(device.persistentUID)
            ignoredUIDs.remove(device.persistentUID)
        } else {
            // Füge zur Ignore-Liste hinzu
            PriorityStore.shared.addIgnoredUID(device.persistentUID)
            ignoredUIDs.insert(device.persistentUID)
            
            // Entferne aus allen Profilen
            ProfileManager.shared.removeDeviceFromAllProfiles(uid: device.persistentUID)
        }
        
        // Refresh AudioState
        AudioState.shared.refresh()
    }
    
    private func resetAllIgnored() {
        PriorityStore.shared.clearIgnoredUIDs()
        ignoredUIDs.removeAll()
        
        // Refresh AudioState
        AudioState.shared.refresh()
    }
    
    private func forgetDevice(device: AudioDevice) {
        // Entferne aus Ignore-Liste falls vorhanden
        if ignoredUIDs.contains(device.persistentUID) {
            PriorityStore.shared.removeIgnoredUID(device.persistentUID)
            ignoredUIDs.remove(device.persistentUID)
        }
        
        // Entferne aus allen Profilen
        ProfileManager.shared.removeDeviceFromAllProfiles(uid: device.persistentUID)
        
        // Entferne aus DeviceRegistry (dauerhaft vergessen)
        DeviceRegistry.shared.removeDevice(uid: device.persistentUID)
        
        // Aktualisiere die Listen
        loadDevices()
        
        // Refresh AudioState
        AudioState.shared.refresh()
    }
}

struct IgnoreDeviceList: View {
    let devices: [AudioDevice]
    let ignoredUIDs: Set<String>
    let onToggle: (AudioDevice) -> Void
    let onForget: (AudioDevice) -> Void
    
    var body: some View {
        VStack(spacing: 6) {
            List {
                ForEach(devices, id: \.identityKey) { device in
                    IgnoreDeviceRow(
                        device: device,
                        isIgnored: ignoredUIDs.contains(device.persistentUID),
                        onToggle: {
                            onToggle(device)
                        },
                        onForget: {
                            onForget(device)
                        }
                    )
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 2, leading: 6, bottom: 2, trailing: 6))
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .scrollIndicators(.hidden)
            .scrollDisabled(true)
            .frame(height: CGFloat(devices.count) * 50 + 6)
        }
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(6)
        .padding(1)
    }
}

struct IgnoreDeviceRow: View {
    let device: AudioDevice
    let isIgnored: Bool
    let onToggle: () -> Void
    let onForget: () -> Void
    
    var subtitle: String {
        switch device.state {
        case .offline:
            return "Offline"
        case .active:
            return device.isInput ? "Active Input" : "Active Output"
        case .connected:
            return "Connected but not active"
        }
    }
    
    var body: some View {
        HStack(spacing: 10) {
            // Icon
            Image(nsImage: device.iconNSImage)
                .resizable()
                .frame(width: 18, height: 18)
            
            // Name und Subtitle
            VStack(alignment: .leading, spacing: 2) {
                Text(device.name)
                    .font(.system(size: 14))
                
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Status Circle
            Circle()
                .fill(Color(device.statusColorNS))
                .frame(width: 10, height: 10)
            
            // Eye Toggle Button
            Button {
                onToggle()
            } label: {
                Image(systemName: isIgnored ? "eye.slash" : "eye")
                    .foregroundColor(isIgnored ? .secondary : .primary)
                    .help(isIgnored ? "Ignoriert - Klicken zum Aktivieren" : "Sichtbar - Klicken zum Ignorieren")
            }
            .buttonStyle(.borderless)
            
            // Forget Button
            Button {
                onForget()
            } label: {
                Image(systemName: "xmark.circle")
                    .foregroundColor(.secondary)
                    .help("Gerät dauerhaft vergessen")
            }
            .buttonStyle(.borderless)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(NSColor.textBackgroundColor))
        .cornerRadius(5)
        .opacity(isIgnored ? 0.6 : 1.0)
    }
}

