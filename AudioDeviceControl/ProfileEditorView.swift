import SwiftUI

struct ProfileEditorView: View {
    @ObservedObject private var profileManager = ProfileManager.shared
    @ObservedObject private var audioState = AudioState.shared
    
    @Binding var isPresented: Bool
    @State private var editingProfile: Profile
    @State private var inputDevices: [AudioDevice] = []
    @State private var outputDevices: [AudioDevice] = []
    let window: NSWindow?
    
    init(profile: Profile, isPresented: Binding<Bool>, window: NSWindow? = nil) {
        self._editingProfile = State(initialValue: profile)
        self._isPresented = isPresented
        self.window = window
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Profil bearbeiten")
                    .font(.title2)
                    .bold()
                Spacer()
                Button("Abbrechen") {
                    if let window = window {
                        window.close()
                    } else {
                        isPresented = false
                    }
                }
                .buttonStyle(.bordered)
                Button("Speichern") {
                    saveProfile()
                    if let window = window {
                        window.close()
                    } else {
                        isPresented = false
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            
            Divider()
            
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 20) {
                    // Profil-Name
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Profil-Name")
                            .font(.headline)
                        TextField("Profil-Name", text: $editingProfile.name)
                            .textFieldStyle(.roundedBorder)
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 12)
                    
                    // Emoji-Auswahl
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Icon (Emoji)")
                            .font(.headline)
                            .padding(.horizontal, 18)
                        HStack(spacing: 12) {
                            ForEach(ProfileEmojiPreset.emojis, id: \.self) { emoji in
                                Button {
                                    editingProfile.icon = emoji
                                } label: {
                                    Text(emoji)
                                        .font(.system(size: 32))
                                        .frame(width: 50, height: 50)
                                        .background(
                                            editingProfile.icon == emoji
                                                ? Color.accentColor.opacity(0.2)
                                                : Color.clear
                                        )
                                        .cornerRadius(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(
                                                    editingProfile.icon == emoji
                                                        ? Color.accentColor
                                                        : Color.clear,
                                                    lineWidth: 2
                                                )
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 18)
                    }
                    
                    // Farb-Auswahl
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Farbe")
                            .font(.headline)
                            .padding(.horizontal, 18)
                        HStack(spacing: 12) {
                            ForEach(ProfileColorPreset.colors, id: \.hex) { colorPreset in
                                Button {
                                    editingProfile.color = colorPreset.hex
                                } label: {
                                    Circle()
                                        .fill(Color(hex: colorPreset.hex))
                                        .frame(width: 40, height: 40)
                                        .overlay(
                                            Circle()
                                                .stroke(
                                                    editingProfile.color == colorPreset.hex
                                                        ? Color.primary
                                                        : Color.clear,
                                                    lineWidth: 3
                                                )
                                        )
                                        .overlay(
                                            editingProfile.color == colorPreset.hex
                                                ? Image(systemName: "checkmark")
                                                    .foregroundColor(.white)
                                                    .font(.system(size: 14, weight: .bold))
                                                : nil
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 18)
                    }
                    
                    Divider()
                        .padding(.horizontal, 18)
                        .padding(.vertical, 4)
                    
                    // Output-Geräte
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Output-Geräte")
                            .font(.headline)
                            .padding(.horizontal, 18)
                            .padding(.top, 16)
                            .padding(.bottom, 4)
                        
                        if outputDevices.isEmpty {
                            Text("Keine Output-Geräte gefunden")
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 18)
                                .padding(.vertical, 20)
                        } else {
                            DeviceReorderList(
                                devices: $outputDevices,
                                deviceType: "Output"
                            )
                            .padding(.horizontal, 18)
                        }
                    }
                    .padding(.top, 12)
                    
                    Divider()
                        .padding(.horizontal, 18)
                        .padding(.vertical, 4)
                    
                    // Input-Geräte
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Input-Geräte")
                            .font(.headline)
                            .padding(.horizontal, 18)
                            .padding(.top, 16)
                            .padding(.bottom, 4)
                        
                        if inputDevices.isEmpty {
                            Text("Keine Input-Geräte gefunden")
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 18)
                                .padding(.vertical, 20)
                        } else {
                            DeviceReorderList(
                                devices: $inputDevices,
                                deviceType: "Input"
                            )
                            .padding(.horizontal, 18)
                        }
                    }
                    .padding(.top, 12)
                    
                    Divider()
                        .padding(.horizontal, 18)
                        .padding(.vertical, 8)
                    
                    // Farbcode-Erklärung (ganz unten)
                    VStack(alignment: .leading, spacing: 8) {
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
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 8)
                    .padding(.bottom, 20)
                    
                }
            }
        }
        .frame(minWidth: 700, idealWidth: 800, minHeight: 600, idealHeight: 900)
        .onAppear {
            print("📋 ProfileEditor: onAppear called")
            loadProfileData()
            // Stelle sicher, dass Geräte geladen werden
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                print("📋 ProfileEditor: Refreshing device lists after delay")
                refreshDeviceLists()
            }
        }
        .onChange(of: audioState.listVersion) { _, _ in
            refreshDeviceLists()
        }
    }
    
    private func loadProfileData() {
        // Lade Geräte basierend auf Profil-Prioritäten
        refreshDeviceLists()
        
        print("📋 ProfileEditor: Loaded \(inputDevices.count) input devices, \(outputDevices.count) output devices")
    }
    
    private func refreshDeviceLists() {
        // Lade alle Geräte direkt, nicht gefiltert durch aktives Profil
        let allInputs = loadAllInputDevices()
        let allOutputs = loadAllOutputDevices()
        
        // Lade aktuelle Default-Geräte für korrekte State-Bestimmung
        let defaultInputID = AudioDeviceManager.shared.getDefaultInputDevice()
        let defaultOutputID = AudioDeviceManager.shared.getDefaultOutputDevice()
        
        print("📋 ProfileEditor: Found \(allInputs.count) total input devices, \(allOutputs.count) total output devices")
        
        // Erstelle Lookup-Maps für schnellen Zugriff
        let inputDeviceMap: [String: AudioDevice] = Dictionary(uniqueKeysWithValues: allInputs.map { ($0.persistentUID, $0) })
        let outputDeviceMap: [String: AudioDevice] = Dictionary(uniqueKeysWithValues: allOutputs.map { ($0.persistentUID, $0) })
        
        // Baue Input-Liste basierend auf Profil-Priorität (exakte Reihenfolge beibehalten)
        var orderedInputs: [AudioDevice] = []
        
        // WICHTIG: Durchlaufe Prioritätsliste in exakter Reihenfolge
        // Jedes Gerät wird an seiner Position hinzugefügt, entweder als verbundenes Gerät oder als Offline-Placeholder
        for uid in editingProfile.inputOrder {
            if let device = inputDeviceMap[uid] {
                // Gerät ist verbunden → verwende es (State wird automatisch korrekt gesetzt)
                orderedInputs.append(device)
            } else {
                // Gerät ist offline → erstelle Placeholder
                if let meta = DeviceRegistry.shared.metadata(for: uid), meta.isInput {
                    let placeholder = AudioDeviceFactory.makeOffline(
                        uid: uid,
                        name: meta.name,
                        isInput: true,
                        isOutput: false
                    )
                    orderedInputs.append(placeholder)
                } else {
                    // Keine Metadaten, aber Gerät ist in Prioritätsliste → Fallback
                    let placeholder = AudioDeviceFactory.makeOffline(
                        uid: uid,
                        name: uid,
                        isInput: true,
                        isOutput: false
                    )
                    orderedInputs.append(placeholder)
                }
            }
        }
        
        // Neue Geräte (nicht in Prioritätsliste) am Ende hinzufügen
        for device in allInputs {
            if !orderedInputs.contains(where: { $0.persistentUID == device.persistentUID }) {
                orderedInputs.append(device)
            }
        }
        
        inputDevices = orderedInputs
        
        print("📋 ProfileEditor: Final input devices: \(inputDevices.count)")
        
        // Baue Output-Liste basierend auf Profil-Priorität (exakte Reihenfolge beibehalten)
        var orderedOutputs: [AudioDevice] = []
        
        // WICHTIG: Durchlaufe Prioritätsliste in exakter Reihenfolge
        for uid in editingProfile.outputOrder {
            if let device = outputDeviceMap[uid] {
                // Gerät ist verbunden → verwende es
                orderedOutputs.append(device)
            } else {
                // Gerät ist offline → erstelle Placeholder
                if let meta = DeviceRegistry.shared.metadata(for: uid), meta.isOutput {
                    let placeholder = AudioDeviceFactory.makeOffline(
                        uid: uid,
                        name: meta.name,
                        isInput: false,
                        isOutput: true
                    )
                    orderedOutputs.append(placeholder)
                } else {
                    // Keine Metadaten, aber Gerät ist in Prioritätsliste → Fallback
                    let placeholder = AudioDeviceFactory.makeOffline(
                        uid: uid,
                        name: uid,
                        isInput: false,
                        isOutput: true
                    )
                    orderedOutputs.append(placeholder)
                }
            }
        }
        
        // Neue Geräte (nicht in Prioritätsliste) am Ende hinzufügen
        for device in allOutputs {
            if !orderedOutputs.contains(where: { $0.persistentUID == device.persistentUID }) {
                orderedOutputs.append(device)
            }
        }
        
        outputDevices = orderedOutputs
        
        print("📋 ProfileEditor: Final output devices: \(outputDevices.count)")
    }
    
    private func loadAllInputDevices() -> [AudioDevice] {
        let ids = AudioDeviceManager.shared.getAllDeviceIDs()
        let defaultInputID = AudioDeviceManager.shared.getDefaultInputDevice()
        let defaultOutputID = AudioDeviceManager.shared.getDefaultOutputDevice()
        
        var inputs: [AudioDevice] = []
        
        for id in ids {
            let isInput = AudioDeviceManager.shared.isInputDevice(id)
            let isOutput = AudioDeviceManager.shared.isOutputDevice(id)
            
            if !isInput { continue }
            
            guard let device = AudioDeviceFactory.make(
                from: id,
                isInput: isInput,
                isOutput: isOutput,
                defaultInputID: defaultInputID,
                defaultOutputID: defaultOutputID
            ) else { continue }
            
            inputs.append(device)
        }
        
        // Register devices
        DeviceRegistry.shared.registerDevices(inputs)
        
        return inputs
    }
    
    private func loadAllOutputDevices() -> [AudioDevice] {
        let ids = AudioDeviceManager.shared.getAllDeviceIDs()
        let defaultInputID = AudioDeviceManager.shared.getDefaultInputDevice()
        let defaultOutputID = AudioDeviceManager.shared.getDefaultOutputDevice()
        
        var outputs: [AudioDevice] = []
        
        for id in ids {
            let isInput = AudioDeviceManager.shared.isInputDevice(id)
            let isOutput = AudioDeviceManager.shared.isOutputDevice(id)
            
            if !isOutput { continue }
            
            guard let device = AudioDeviceFactory.make(
                from: id,
                isInput: isInput,
                isOutput: isOutput,
                defaultInputID: defaultInputID,
                defaultOutputID: defaultOutputID
            ) else { continue }
            
            outputs.append(device)
        }
        
        // Register devices
        DeviceRegistry.shared.registerDevices(outputs)
        
        return outputs
    }
    
    private func findDevice(by uid: String) -> AudioDevice? {
        let allInputs = loadAllInputDevices()
        let allOutputs = loadAllOutputDevices()
        
        return allInputs.first(where: { $0.persistentUID == uid })
            ?? allOutputs.first(where: { $0.persistentUID == uid })
            ?? DeviceRegistry.shared.metadata(for: uid).map { meta in
                AudioDeviceFactory.makeOffline(
                    uid: uid,
                    name: meta.name,
                    isInput: meta.isInput,
                    isOutput: meta.isOutput
                )
            }
    }
    
    private func saveProfile() {
        // Speichere Prioritäten
        editingProfile.inputOrder = inputDevices.map { $0.persistentUID }
        editingProfile.outputOrder = outputDevices.map { $0.persistentUID }
        
        // Aktualisiere Profil im Manager
        profileManager.updateProfile(editingProfile)
        
        // Wenn es das aktive Profil ist, lade es neu
        if profileManager.activeProfile?.id == editingProfile.id {
            profileManager.setActiveProfile(editingProfile)
            AudioState.shared.loadProfile(editingProfile)
        }
        
        if let window = window {
            window.close()
        } else {
            isPresented = false
        }
    }
}

// Extension für Hex-Farben
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6: // RGB
            (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255.0,
            green: Double(g) / 255.0,
            blue: Double(b) / 255.0,
            opacity: 1.0
        )
    }
}

