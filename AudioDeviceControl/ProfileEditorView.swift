import SwiftUI

struct ProfileEditorView: View {
    @ObservedObject private var profileManager = ProfileManager.shared
    @ObservedObject private var audioState = AudioState.shared
    
    @Binding var isPresented: Bool
    @Binding var showSettings: Bool
    @State private var editingProfile: Profile
    @State private var inputDevices: [AudioDevice] = []
    @State private var outputDevices: [AudioDevice] = []
    @State private var ignoredInputDevices: [AudioDevice] = []
    @State private var ignoredOutputDevices: [AudioDevice] = []
    
    init(profile: Profile, isPresented: Binding<Bool>, showSettings: Binding<Bool>) {
        self._editingProfile = State(initialValue: profile)
        self._isPresented = isPresented
        self._showSettings = showSettings
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header - nur Titel
            VStack(spacing: 0) {
                Text("Profil bearbeiten")
                    .font(.title3)
                    .bold()
                    .padding(.top, 12)
                    .padding(.bottom, 8)
                
                Divider()
            }
            
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 12) {
                    // Profil-Einstellungen - ganz oben
                    VStack(alignment: .leading, spacing: 20) {
                        // Profil-Name
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Profil-Name")
                                .font(.headline)
                            TextField("Profil-Name", text: $editingProfile.name)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        // Emoji-Auswahl (kompakt) - zentriert
                        VStack(alignment: .center, spacing: 6) {
                            Text("Icon")
                                .font(.headline)
                                .foregroundColor(.primary)
                            HStack {
                                Spacer()
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
                                Spacer()
                            }
                        }
                        
                        // Separator zwischen Icon und Farbe
                        Divider()
                            .padding(.vertical, 8)
                        
                        // Farb-Auswahl (kompakt) - zentriert
                        VStack(alignment: .center, spacing: 6) {
                            Text("Farbe")
                                .font(.headline)
                                .foregroundColor(.primary)
                            HStack {
                                Spacer()
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
                                Spacer()
                            }
                        }
                        
                        // Separator zwischen Farbe und WiFi
                        Divider()
                            .padding(.vertical, 8)
                        
                        // WiFi-Netzwerk (optional) - zentriert
                        VStack(alignment: .center, spacing: 6) {
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
                        
                        // Separator zwischen WiFi und Standardprofil
                        Divider()
                            .padding(.vertical, 8)
                        
                        // Default-Profil Checkbox - zentriert
                        VStack(alignment: .center, spacing: 6) {
                            Text("Als Standard-Profil verwenden")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            HStack {
                                Spacer()
                                VStack(alignment: .center, spacing: 4) {
                                    Toggle("", isOn: Binding(
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
                                    
                                    Text("Wird beim App-Start oder beim Löschen des aktiven Profils verwendet")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
                    
                    Divider()
                        .padding(.horizontal, 12)
                        .padding(.vertical, 2)
                    
                    // Device Priorities Überschrift und Legende
                    VStack(alignment: .center, spacing: 8) {
                        Text("Geräte-Prioritäten")
                            .font(.headline)
                        
                        // Farbcode-Erklärung
                        VStack(spacing: 2) {
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
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
                    .padding(.bottom, 4)
                    
                    // Separator zwischen Legende und Output-Geräte
                    Divider()
                        .padding(.horizontal, 12)
                        .padding(.vertical, 2)
                    
                    // Output-Geräte - darunter
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
                            Text("Keine Ausgabe-Geräte gefunden")
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 12)
                        } else {
                            DeviceReorderList(
                                devices: $outputDevices,
                                deviceType: "Output",
                                onIgnore: { device in
                                    ignoreDevice(device, isInput: false)
                                }
                            )
                            .padding(.horizontal, 12)
                        }
                    }
                    .padding(.top, 8)
                    
                    Divider()
                        .padding(.horizontal, 12)
                        .padding(.vertical, 2)
                    
                    // Input-Geräte - darunter
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
                            Text("Keine Eingabe-Geräte gefunden")
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 12)
                        } else {
                            DeviceReorderList(
                                devices: $inputDevices,
                                deviceType: "Input",
                                onIgnore: { device in
                                    ignoreDevice(device, isInput: true)
                                }
                            )
                            .padding(.horizontal, 12)
                        }
                    }
                    .padding(.top, 8)
                    
                    Divider()
                        .padding(.horizontal, 12)
                        .padding(.vertical, 2)
                    
                    // Ignorierte Geräte - ganz unten
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Spacer()
                            Text("Ignorierte Geräte")
                                .font(.headline)
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.top, 10)
                        .padding(.bottom, 2)
                        
                        Text("Diese Geräte werden in diesem Profil nicht verwendet und erscheinen nicht in der Prioritätsliste.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 12)
                            .padding(.bottom, 4)
                        
                        // Ignorierte Output-Geräte
                        if !ignoredOutputDevices.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Ausgabe-Geräte")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 12)
                                
                                VStack(spacing: 4) {
                                    ForEach(ignoredOutputDevices, id: \.identityKey) { device in
                                        ignoredDeviceRow(device, isInput: false)
                                    }
                                }
                                .padding(.horizontal, 6)
                            }
                            .padding(.bottom, 8)
                        }
                        
                        // Ignorierte Input-Geräte
                        if !ignoredInputDevices.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Eingabe-Geräte")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 12)
                                
                                VStack(spacing: 4) {
                                    ForEach(ignoredInputDevices, id: \.identityKey) { device in
                                        ignoredDeviceRow(device, isInput: true)
                                    }
                                }
                                .padding(.horizontal, 6)
                            }
                        }
                        
                        if ignoredInputDevices.isEmpty && ignoredOutputDevices.isEmpty {
                            Text("Keine ignorierten Geräte")
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 12)
                        }
                    }
                    .padding(.top, 8)
                    
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
        .onReceive(NotificationCenter.default.publisher(for: .saveProfileRequested)) { _ in
            saveProfile()
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
        
        // Filtere ignorierte und gelöschte Geräte (profil-basiert)
        let ignoredInputUIDs = Set(editingProfile.ignoredInputUIDs)
        let ignoredOutputUIDs = Set(editingProfile.ignoredOutputUIDs)
        let deletedUIDs = Set(PriorityStore.shared.loadDeletedUIDs())
        
        print("📋 ProfileEditor: Found \(allInputs.count) total input devices, \(allOutputs.count) total output devices")
        
        // Erstelle Lookup-Maps für schnellen Zugriff
        let inputDeviceMap: [String: AudioDevice] = Dictionary(uniqueKeysWithValues: allInputs.map { ($0.persistentUID, $0) })
        let outputDeviceMap: [String: AudioDevice] = Dictionary(uniqueKeysWithValues: allOutputs.map { ($0.persistentUID, $0) })
        
        // Baue Input-Liste basierend auf Profil-Priorität (exakte Reihenfolge beibehalten)
        var orderedInputs: [AudioDevice] = []
        
        // WICHTIG: Durchlaufe Prioritätsliste in exakter Reihenfolge
        // Jedes Gerät wird an seiner Position hinzugefügt, entweder als verbundenes Gerät oder als Offline-Placeholder
        // ABER: Ignorierte und gelöschte Geräte werden übersprungen
        for uid in editingProfile.inputOrder {
            // Überspringe ignorierte und gelöschte Geräte
            if ignoredInputUIDs.contains(uid) || deletedUIDs.contains(uid) {
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
        // ABER: Ignorierte und gelöschte Geräte werden nicht hinzugefügt
        for device in allInputs {
            if !orderedInputs.contains(where: { $0.persistentUID == device.persistentUID }) {
                if !ignoredInputUIDs.contains(device.persistentUID) && !deletedUIDs.contains(device.persistentUID) {
                    orderedInputs.append(device)
                }
            }
        }
        
        // Baue Liste der ignorierten Input-Geräte
        var ignoredInputs: [AudioDevice] = []
        for uid in editingProfile.ignoredInputUIDs {
            if let device = inputDeviceMap[uid] {
                ignoredInputs.append(device)
            } else if let meta = DeviceRegistry.shared.metadata(for: uid), meta.isInput {
                let placeholder = AudioDeviceFactory.makeOffline(
                    uid: uid,
                    name: meta.name,
                    isInput: true,
                    isOutput: false
                )
                ignoredInputs.append(placeholder)
            }
        }
        
        inputDevices = orderedInputs
        
        print("📋 ProfileEditor: Final input devices: \(inputDevices.count)")
        
        // Baue Output-Liste basierend auf Profil-Priorität (exakte Reihenfolge beibehalten)
        var orderedOutputs: [AudioDevice] = []
        
        // WICHTIG: Durchlaufe Prioritätsliste in exakter Reihenfolge
        // ABER: Ignorierte und gelöschte Geräte werden übersprungen
        for uid in editingProfile.outputOrder {
            // Überspringe ignorierte und gelöschte Geräte
            if ignoredOutputUIDs.contains(uid) || deletedUIDs.contains(uid) {
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
        // ABER: Ignorierte und gelöschte Geräte werden nicht hinzugefügt
        for device in allOutputs {
            if !orderedOutputs.contains(where: { $0.persistentUID == device.persistentUID }) {
                if !ignoredOutputUIDs.contains(device.persistentUID) && !deletedUIDs.contains(device.persistentUID) {
                    orderedOutputs.append(device)
                }
            }
        }
        
        // Baue Liste der ignorierten Output-Geräte
        var ignoredOutputs: [AudioDevice] = []
        for uid in editingProfile.ignoredOutputUIDs {
            if let device = outputDeviceMap[uid] {
                ignoredOutputs.append(device)
            } else if let meta = DeviceRegistry.shared.metadata(for: uid), meta.isOutput {
                let placeholder = AudioDeviceFactory.makeOffline(
                    uid: uid,
                    name: meta.name,
                    isInput: false,
                    isOutput: true
                )
                ignoredOutputs.append(placeholder)
            }
        }
        
        inputDevices = orderedInputs
        outputDevices = orderedOutputs
        ignoredInputDevices = ignoredInputs
        ignoredOutputDevices = ignoredOutputs
        
        print("📋 ProfileEditor: Final input devices: \(inputDevices.count), ignored: \(ignoredInputDevices.count)")
        print("📋 ProfileEditor: Final output devices: \(outputDevices.count), ignored: \(ignoredOutputDevices.count)")
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
    
    private func ignoredDeviceRow(_ device: AudioDevice, isInput: Bool) -> some View {
        HStack(spacing: 10) {
            DeviceTableCellView(
                icon: device.iconNSImage,
                name: device.name,
                subtitle: device.state == .offline ? "Offline" : "Ignoriert",
                statusColor: device.state == .offline ? .systemGray : .orange
            )
            
            Spacer()
            
            // Augensymbol zum Ent-ignorieren
            Button {
                unignoreDevice(device, isInput: isInput)
            } label: {
                Image(systemName: "eye.slash.fill")
                    .foregroundColor(.orange)
                    .font(.system(size: 14))
            }
            .buttonStyle(.borderless)
            .help("Ignorierung aufheben")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(NSColor.textBackgroundColor))
        .cornerRadius(5)
    }
    
    private func ignoreDevice(_ device: AudioDevice, isInput: Bool) {
        let uid = device.persistentUID
        
        if isInput {
            // Entferne aus inputOrder falls vorhanden
            editingProfile.inputOrder.removeAll { $0 == uid }
            // Füge zu ignoredInputUIDs hinzu falls nicht vorhanden
            if !editingProfile.ignoredInputUIDs.contains(uid) {
                editingProfile.ignoredInputUIDs.append(uid)
            }
        } else {
            // Entferne aus outputOrder falls vorhanden
            editingProfile.outputOrder.removeAll { $0 == uid }
            // Füge zu ignoredOutputUIDs hinzu falls nicht vorhanden
            if !editingProfile.ignoredOutputUIDs.contains(uid) {
                editingProfile.ignoredOutputUIDs.append(uid)
            }
        }
        
        refreshDeviceLists()
    }
    
    private func unignoreDevice(_ device: AudioDevice, isInput: Bool) {
        let uid = device.persistentUID
        
        if isInput {
            editingProfile.ignoredInputUIDs.removeAll { $0 == uid }
        } else {
            editingProfile.ignoredOutputUIDs.removeAll { $0 == uid }
        }
        
        refreshDeviceLists()
    }
    
    func saveProfile() {
        // Speichere Prioritäten
        editingProfile.inputOrder = inputDevices.map { $0.persistentUID }
        editingProfile.outputOrder = outputDevices.map { $0.persistentUID }
        // Ignorierte Geräte sind bereits in editingProfile.ignoredInputUIDs/ignoredOutputUIDs
        
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
    @State private var savedSSIDs: [String] = []
    @State private var isLoadingSSIDs: Bool = false
    @State private var ssidLoadError: String?
    
    private var currentSSID: String? {
        WiFiManager.shared.getCurrentSSID()
    }
    
    private var allSSIDs: [String?] {
        var ssids: [String?] = [nil] // "Kein WiFi" Option
        let current = currentSSID
        
        print("📡 WiFiPickerView: currentSSID = \(current ?? "nil"), knownSSIDs = \(knownSSIDs.count), savedSSIDs = \(savedSSIDs.count)")
        
        // 1. Aktuelles WiFi IMMER zuerst hinzufügen (auch wenn noch nicht gespeichert)
        if let current = current {
            ssids.append(current)
            print("📡 WiFiPickerView: Aktuelles WiFi hinzugefügt: \(current)")
        } else {
            print("📡 WiFiPickerView: Kein aktuelles WiFi gefunden")
        }
        
        // 2. Alle gespeicherten macOS WLANs hinzufügen (alphabetisch sortiert, ohne Duplikate)
        var addedSSIDs = Set<String>()
        if let current = current {
            addedSSIDs.insert(current)
        }
        
        for savedSSID in savedSSIDs {
            if !addedSSIDs.contains(savedSSID) {
                ssids.append(savedSSID)
                addedSSIDs.insert(savedSSID)
                print("📡 WiFiPickerView: Gespeichertes WiFi hinzugefügt: \(savedSSID)")
            }
        }
        
        // 3. Bekannte aus Profilen hinzufügen (nur die, die noch nicht in Liste sind)
        for knownSSID in knownSSIDs {
            if !addedSSIDs.contains(knownSSID) {
                ssids.append(knownSSID)
                addedSSIDs.insert(knownSSID)
                print("📡 WiFiPickerView: Bekanntes WiFi hinzugefügt: \(knownSSID)")
            }
        }
        
        print("📡 WiFiPickerView: Gesamt \(ssids.count) Einträge in der Liste")
        return ssids
    }
    
    private func loadSavedSSIDs() {
        guard !isLoadingSSIDs else { return }
        
        isLoadingSSIDs = true
        ssidLoadError = nil
        
        DispatchQueue.global(qos: .userInitiated).async {
            let ssids = WiFiManager.shared.getAllSavedWiFiNetworks()
            
            DispatchQueue.main.async {
                self.savedSSIDs = ssids
                self.isLoadingSSIDs = false
                
                if ssids.isEmpty {
                    // Prüfe ob es ein Fehler war oder einfach keine gespeicherten WLANs
                    // Wenn wir ein Interface finden konnten, aber keine SSIDs, ist das OK
                    if WiFiManager.shared.findWiFiInterface() == nil {
                        self.ssidLoadError = "WiFi-Interface nicht gefunden. Stelle sicher, dass WiFi aktiviert ist."
                    }
                } else {
                    self.ssidLoadError = nil
                }
                
                // Force UI refresh
                self.refreshID = UUID()
            }
        }
    }
    
    private var hasLocationPermission: Bool {
        WiFiManager.shared.hasLocationPermission()
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            HStack {
                Spacer()
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
                    loadSavedSSIDs()
                    print("📡 WiFiPickerView: Manueller Refresh")
                } label: {
                    if isLoadingSSIDs {
                        ProgressView()
                            .scaleEffect(0.7)
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                .buttonStyle(.bordered)
                .help("WiFi-Liste aktualisieren")
                .disabled(isLoadingSSIDs)
                Spacer()
            }
            
            // Fehlermeldung beim Laden gespeicherter WLANs
            if let error = ssidLoadError {
                HStack {
                    Spacer()
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    Spacer()
                }
                .padding(.horizontal, 4)
            }
            
            // Warnung wenn Location Services Berechtigung fehlt
            if !hasLocationPermission {
                VStack(alignment: .center, spacing: 8) {
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
            // Lade gespeicherte WLANs beim Erscheinen
            loadSavedSSIDs()
            
            // Starte Timer zum periodischen Aktualisieren des aktuellen WiFi
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

