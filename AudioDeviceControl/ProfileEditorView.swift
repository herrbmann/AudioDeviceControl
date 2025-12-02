import SwiftUI

struct ProfileEditorView: View {
    @ObservedObject private var profileManager = ProfileManager.shared
    @ObservedObject private var audioState = AudioState.shared
    
    @Binding var isPresented: Bool
    @Binding var showSettings: Bool
    @State private var editingProfile: Profile
    @State private var inputDevices: [AudioDevice] = []
    @State private var outputDevices: [AudioDevice] = []
    
    init(profile: Profile, isPresented: Binding<Bool>, showSettings: Binding<Bool>) {
        self._editingProfile = State(initialValue: profile)
        self._isPresented = isPresented
        self._showSettings = showSettings
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button {
                    isPresented = false
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Zurück")
                    }
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Text("Profil bearbeiten")
                    .font(.title3)
                    .bold()
                
                Spacer()
                
                Button("Abbrechen") {
                    isPresented = false
                }
                .buttonStyle(.bordered)
                Button("Speichern") {
                    saveProfile()
                    isPresented = false
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            
            Divider()
            
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 12) {
                    // Output-Geräte (zuerst)
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Output-Geräte")
                            .font(.headline)
                            .padding(.horizontal, 12)
                            .padding(.top, 10)
                            .padding(.bottom, 2)
                        
                        if outputDevices.isEmpty {
                            Text("Keine Output-Geräte gefunden")
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 12)
                        } else {
                            DeviceReorderList(
                                devices: $outputDevices,
                                deviceType: "Output"
                            )
                            .padding(.horizontal, 12)
                        }
                    }
                    .padding(.top, 8)
                    
                    Divider()
                        .padding(.horizontal, 12)
                        .padding(.vertical, 2)
                    
                    // Input-Geräte (zweiter)
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Input-Geräte")
                            .font(.headline)
                            .padding(.horizontal, 12)
                            .padding(.top, 10)
                            .padding(.bottom, 2)
                        
                        if inputDevices.isEmpty {
                            Text("Keine Input-Geräte gefunden")
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 12)
                        } else {
                            DeviceReorderList(
                                devices: $inputDevices,
                                deviceType: "Input"
                            )
                            .padding(.horizontal, 12)
                        }
                    }
                    .padding(.top, 8)
                    
                    Divider()
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                    
                    // Profil-Name und Einstellungen (dritter)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Profil-Name")
                            .font(.headline)
                        TextField("Profil-Name", text: $editingProfile.name)
                            .textFieldStyle(.roundedBorder)
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
                    
                    // Emoji-Auswahl (kompakt)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Icon")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        HStack(spacing: 6) {
                            ForEach(ProfileEmojiPreset.emojis, id: \.self) { emoji in
                                Button {
                                    editingProfile.icon = emoji
                                } label: {
                                    Text(emoji)
                                        .font(.system(size: 24))
                                        .frame(width: 36, height: 36)
                                        .background(
                                            editingProfile.icon == emoji
                                                ? Color.accentColor.opacity(0.2)
                                                : Color.clear
                                        )
                                        .cornerRadius(6)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 6)
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
                    }
                    .padding(.horizontal, 12)
                    
                    // Farb-Auswahl (kompakt)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Farbe")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        HStack(spacing: 6) {
                            ForEach(ProfileColorPreset.colors, id: \.hex) { colorPreset in
                                Button {
                                    editingProfile.color = colorPreset.hex
                                } label: {
                                    Circle()
                                        .fill(Color(hex: colorPreset.hex))
                                        .frame(width: 28, height: 28)
                                        .overlay(
                                            Circle()
                                                .stroke(
                                                    editingProfile.color == colorPreset.hex
                                                        ? Color.primary
                                                        : Color.clear,
                                                    lineWidth: 2.5
                                                )
                                        )
                                        .overlay(
                                            editingProfile.color == colorPreset.hex
                                                ? Image(systemName: "checkmark")
                                                    .foregroundColor(.white)
                                                    .font(.system(size: 11, weight: .bold))
                                                : nil
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    
                    // Default-Profil Checkbox
                    VStack(alignment: .leading, spacing: 6) {
                        Toggle("Als Standard-Profil verwenden", isOn: Binding(
                            get: { editingProfile.isDefault },
                            set: { newValue in
                                editingProfile.isDefault = newValue
                                if newValue {
                                    // Wenn dieses Profil als Default gesetzt wird, entferne Default von anderen
                                    profileManager.setDefaultProfile(editingProfile)
                                }
                            }
                        ))
                        .toggleStyle(.checkbox)
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
                    
                    // WiFi-Netzwerk (optional)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("WiFi-Netzwerk (optional)")
                            .font(.headline)
                        
                        WiFiPickerView(
                            selectedSSID: Binding(
                                get: { editingProfile.wifiSSID },
                                set: { editingProfile.wifiSSID = $0 }
                            ),
                            knownSSIDs: profileManager.getAllKnownWiFiSSIDs()
                        )
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
                    
                    Divider()
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                    
                    // Farbcode-Erklärung (ganz unten)
                    VStack(alignment: .leading, spacing: 4) {
                        VStack(spacing: 2) {
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
                    .padding(.horizontal, 12)
                    .padding(.top, 4)
                    .padding(.bottom, 12)
                    
                }
            }
        }
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
        
        // Lade ignorierte Geräte
        let ignoredUIDs = Set(PriorityStore.shared.loadIgnoredUIDs())
        
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
        // ABER: Ignorierte Geräte werden übersprungen
        for uid in editingProfile.inputOrder {
            // Überspringe ignorierte Geräte
            if ignoredUIDs.contains(uid) {
                continue
            }
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
        // ABER: Ignorierte Geräte werden übersprungen
        for device in allInputs {
            // Überspringe ignorierte Geräte
            if ignoredUIDs.contains(device.persistentUID) {
                continue
            }
            if !orderedInputs.contains(where: { $0.persistentUID == device.persistentUID }) {
                orderedInputs.append(device)
            }
        }
        
        inputDevices = orderedInputs
        
        print("📋 ProfileEditor: Final input devices: \(inputDevices.count)")
        
        // Baue Output-Liste basierend auf Profil-Priorität (exakte Reihenfolge beibehalten)
        var orderedOutputs: [AudioDevice] = []
        
        // WICHTIG: Durchlaufe Prioritätsliste in exakter Reihenfolge
        // ABER: Ignorierte Geräte werden übersprungen
        for uid in editingProfile.outputOrder {
            // Überspringe ignorierte Geräte
            if ignoredUIDs.contains(uid) {
                continue
            }
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
        // ABER: Ignorierte Geräte werden übersprungen
        for device in allOutputs {
            // Überspringe ignorierte Geräte
            if ignoredUIDs.contains(device.persistentUID) {
                continue
            }
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
        
        // Lade ignorierte Geräte
        let ignoredUIDs = Set(PriorityStore.shared.loadIgnoredUIDs())
        
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
            
            // Filtere ignorierte Geräte
            if ignoredUIDs.contains(device.persistentUID) {
                continue
            }
            
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
        
        // Lade ignorierte Geräte
        let ignoredUIDs = Set(PriorityStore.shared.loadIgnoredUIDs())
        
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
            
            // Filtere ignorierte Geräte
            if ignoredUIDs.contains(device.persistentUID) {
                continue
            }
            
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
    }
}

// WiFi Picker View
struct WiFiPickerView: View {
    @Binding var selectedSSID: String?
    let knownSSIDs: [String]
    @State private var refreshID = UUID()
    @State private var timer: Timer?
    
    private var currentSSID: String? {
        WiFiManager.shared.getCurrentSSID()
    }
    
    private var allSSIDs: [String?] {
        var ssids: [String?] = [nil] // "Kein WiFi" Option
        let current = currentSSID
        
        print("📡 WiFiPickerView: currentSSID = \(current ?? "nil"), knownSSIDs = \(knownSSIDs)")
        
        // Aktuelles WiFi IMMER hinzufügen (auch wenn noch nicht gespeichert)
        if let current = current {
            ssids.append(current)
            print("📡 WiFiPickerView: Aktuelles WiFi hinzugefügt: \(current)")
        } else {
            print("📡 WiFiPickerView: Kein aktuelles WiFi gefunden")
        }
        
        // Alle gemerkten WiFi-Netzwerke hinzufügen (ohne Duplikate)
        for knownSSID in knownSSIDs {
            if knownSSID != current {
                ssids.append(knownSSID)
                print("📡 WiFiPickerView: Bekanntes WiFi hinzugefügt: \(knownSSID)")
            }
        }
        
        print("📡 WiFiPickerView: Gesamt \(ssids.count) Einträge in der Liste")
        return ssids
    }
    
    private var hasLocationPermission: Bool {
        WiFiManager.shared.hasLocationPermission()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Picker("WiFi-Netzwerk", selection: $selectedSSID) {
                    ForEach(allSSIDs, id: \.self) { ssid in
                        if let ssid = ssid {
                            HStack {
                                if ssid == currentSSID {
                                    Image(systemName: "wifi")
                                        .foregroundColor(.blue)
                                }
                                Text(ssid)
                                if ssid == currentSSID {
                                    Text("(aktuell)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .tag(ssid as String?)
                        } else {
                            Text("Kein WiFi")
                                .tag(nil as String?)
                        }
                    }
                }
                .pickerStyle(.menu)
                .id(refreshID) // Force refresh when ID changes
                
                Button {
                    refreshID = UUID()
                    print("📡 WiFiPickerView: Manueller Refresh")
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
                .help("WiFi-Liste aktualisieren")
            }
            
            // Warnung wenn Location Services Berechtigung fehlt
            if !hasLocationPermission {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("Location Services Berechtigung erforderlich")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.orange)
                    }
                    
                    Text("Um WiFi-Netzwerke zu erkennen, benötigt die App Zugriff auf Location Services.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("So aktivierst du die Berechtigung:")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        
                        Text("1. Klicke auf 'Zu System Settings öffnen'")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("2. Scrolle zu 'AudioDeviceControl'")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("3. Aktiviere den Schalter")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("4. Starte die App neu")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack(spacing: 8) {
                        Button {
                            WiFiManager.shared.requestLocationPermission()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "location")
                                Text("Berechtigung anfordern")
                            }
                            .font(.caption)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        
                        Button {
                            WiFiManager.shared.openLocationSettings()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "gear")
                                Text("System Settings öffnen")
                            }
                            .font(.caption)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
                .padding(8)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(6)
            } else if let current = currentSSID {
                Text("Aktuelles WiFi: \(current)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("Kein WiFi verbunden")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .onAppear {
            // Starte Timer zum periodischen Aktualisieren
            timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
                refreshID = UUID()
            }
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
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

