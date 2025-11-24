import Foundation
import CoreAudio
import Combine

final class AudioState: ObservableObject {

    static let shared = AudioState()

    @Published var inputDevices: [AudioDevice] = []
    @Published var outputDevices: [AudioDevice] = []

    @Published var defaultInputID: AudioDeviceID = 0
    @Published var defaultOutputID: AudioDeviceID = 0
    
    @Published var listVersion: Int = 0
    
    private let profileManager = ProfileManager.shared

    private init() {
        refresh()
    }

    // MARK: Refresh
    func refresh() {
        print("🔄 AudioState.refresh()")

        let ids = AudioDeviceManager.shared.getAllDeviceIDs()
        print("🔍 IDs:", ids)

        defaultInputID = AudioDeviceManager.shared.getDefaultInputDevice()
        defaultOutputID = AudioDeviceManager.shared.getDefaultOutputDevice()

        // Priorität aus aktivem Profil laden, oder Fallback zu PriorityStore
        let inputOrder: [String]
        let outputOrder: [String]
        
        if let activeProfile = profileManager.activeProfile {
            inputOrder = activeProfile.inputOrder
            outputOrder = activeProfile.outputOrder
        } else {
            // Fallback zu altem System (für Migration)
            inputOrder = PriorityStore.shared.loadInputOrder()
            outputOrder = PriorityStore.shared.loadOutputOrder()
        }
        
        var inputs: [AudioDevice] = []
        var outputs: [AudioDevice] = []

        for id in ids {

            let isInput  = AudioDeviceManager.shared.isInputDevice(id)
            let isOutput = AudioDeviceManager.shared.isOutputDevice(id)

            if !isInput && !isOutput { continue }

            guard let device = AudioDeviceFactory.make(
                from: id,
                isInput: isInput,
                isOutput: isOutput,
                defaultInputID: defaultInputID,
                defaultOutputID: defaultOutputID
            ) else { continue }

            if device.isInput { inputs.append(device) }
            if device.isOutput { outputs.append(device) }
        }

        // Register currently visible devices (store metadata for offline rendering)
        DeviceRegistry.shared.registerDevices(inputs + outputs)

        // Build lists strictly following stored priority order.
        // Missing devices are shown as offline placeholders at their original positions.
        let newInputDevices  = buildDeviceList(devices: inputs, storedUIDs: inputOrder, wantInput: true, ignored: Set<String>())
        let newOutputDevices = buildDeviceList(devices: outputs, storedUIDs: outputOrder, wantInput: false, ignored: Set<String>())

        DispatchQueue.main.async {
            self.inputDevices  = newInputDevices
            self.outputDevices = newOutputDevices

            print("📌 INPUT Devices:", self.inputDevices.map { $0.name })
            print("📌 OUTPUT Devices:", self.outputDevices.map { $0.name })

            self.applyAutoSelection()
            self.listVersion &+= 1
        }
    }

    // MARK: Update Priority from UI

    func updateInputOrder(_ devices: [AudioDevice]) {
        let uids = devices.map { $0.persistentUID }
        // Update aktives Profil
        if var activeProfile = profileManager.activeProfile {
            activeProfile.inputOrder = uids
            profileManager.updateProfile(activeProfile)
        } else {
            // Fallback zu altem System
            PriorityStore.shared.saveInputOrder(uids)
        }
        refresh()
    }

    func updateOutputOrder(_ devices: [AudioDevice]) {
        let uids = devices.map { $0.persistentUID }
        // Update aktives Profil
        if var activeProfile = profileManager.activeProfile {
            activeProfile.outputOrder = uids
            profileManager.updateProfile(activeProfile)
        } else {
            // Fallback zu altem System
            PriorityStore.shared.saveOutputOrder(uids)
        }
        refresh()
    }

    // MARK: - Build prioritized list including offline placeholders (display only)
    private func buildDeviceList(devices: [AudioDevice],
                                 storedUIDs: [String],
                                 wantInput: Bool,
                                 ignored: Set<String>) -> [AudioDevice] {
        var result: [AudioDevice] = []

        // Fast lookup for currently present devices by UID
        let presentByUID: [String: AudioDevice] = Dictionary(uniqueKeysWithValues: devices.map { ($0.persistentUID, $0) })

        // WICHTIG: Prioritätsreihenfolge wird IMMER beibehalten, unabhängig vom Verbindungsstatus
        // 1) Place all stored UIDs in EXACT order from priority list, using present device or offline placeholder
        for uid in storedUIDs {
            if let dev = presentByUID[uid] {
                // Gerät ist verbunden → verwende es
                result.append(dev)
            } else {
                // Gerät ist nicht verbunden → erstelle Offline-Placeholder
                // Versuche Metadaten aus Registry zu laden
                if let meta = DeviceRegistry.shared.metadata(for: uid) {
                    // Nur hinzufügen, wenn es die richtige Richtung hat
                    if (wantInput && meta.isInput) || (!wantInput && meta.isOutput) {
                        let placeholder = AudioDeviceFactory.makeOffline(uid: uid,
                                                                         name: meta.name,
                                                                         isInput: meta.isInput,
                                                                         isOutput: meta.isOutput)
                        result.append(placeholder)
                    }
                } else {
                    // Keine Metadaten gefunden, aber Gerät ist in Prioritätsliste
                    // Erstelle Placeholder mit UID als Name (Fallback)
                    print("⚠️ No metadata for UID in priority list: \(uid)")
                    let placeholder = AudioDeviceFactory.makeOffline(uid: uid,
                                                                     name: uid,
                                                                     isInput: wantInput,
                                                                     isOutput: !wantInput)
                    result.append(placeholder)
                }
            }
        }

        // 2) Append any currently present devices that are not yet in stored order (new devices)
        // Diese werden am Ende hinzugefügt, da sie nicht in der Prioritätsliste sind
        for dev in devices {
            if !result.contains(where: { $0.persistentUID == dev.persistentUID }) {
                result.append(dev)
            }
        }

        return result
    }

    // NOTE: Superseded by buildDeviceList() for display ordering that preserves offline positions.
    private func applyPriority(devices: [AudioDevice], storedUIDs: [String]) -> [AudioDevice] {

        var ordered: [AudioDevice] = []

        // 1. Geräte aus gespeicherter Reihenfolge
        for uid in storedUIDs {
            if let device = devices.first(where: { $0.persistentUID == uid }) {
                ordered.append(device)
            }
        }

        // 2. neue/unbekannte Geräte hinzufügen
        for dev in devices {
            if !ordered.contains(where: { $0.persistentUID == dev.persistentUID }) {
                ordered.append(dev)
            }
        }

        return ordered
    }

    // MARK: - Offline bekannte Geräte ergänzen
    private func appendOfflineKnownDevices(current: [AudioDevice],
                                           order: [String],
                                           wantInput: Bool) -> [AudioDevice] {
        var result = current
        let knownUIDs = DeviceRegistry.shared.storedUIDs

        // Map for quick lookup
        let presentUIDs = Set(current.map { $0.persistentUID })

        // Iterate in stored order first to keep priorities stable
        for uid in order {
            guard !presentUIDs.contains(uid) else { continue }
            if let meta = DeviceRegistry.shared.metadata(for: uid) {
                // Only include if matches desired direction
                if (wantInput && meta.isInput) || (!wantInput && meta.isOutput) {
                    let placeholder = AudioDeviceFactory.makeOffline(uid: uid,
                                                                     name: meta.name,
                                                                     isInput: meta.isInput,
                                                                     isOutput: meta.isOutput)
                    result.append(placeholder)
                }
            }
        }

        // Also include any other known devices not in order yet (append at end)
        for uid in knownUIDs where !presentUIDs.contains(uid) && !result.contains(where: { $0.persistentUID == uid }) {
            if let meta = DeviceRegistry.shared.metadata(for: uid) {
                if (wantInput && meta.isInput) || (!wantInput && meta.isOutput) {
                    let placeholder = AudioDeviceFactory.makeOffline(uid: uid,
                                                                     name: meta.name,
                                                                     isInput: meta.isInput,
                                                                     isOutput: meta.isOutput)
                    result.append(placeholder)
                }
            }
        }

        return result
    }

    // MARK: Auto-Select

    private func applyAutoSelection() {
        // Priorität aus aktivem Profil laden
        let inputOrder: [String]
        let outputOrder: [String]
        
        if let activeProfile = profileManager.activeProfile {
            inputOrder = activeProfile.inputOrder
            outputOrder = activeProfile.outputOrder
            print("📋 Using profile:", activeProfile.name, "Input order:", inputOrder.count, "Output order:", outputOrder.count)
        } else {
            // Fallback zu altem System (für Migration)
            inputOrder = PriorityStore.shared.loadInputOrder()
            outputOrder = PriorityStore.shared.loadOutputOrder()
            print("📋 Using fallback priority store")
        }
        
        // Erstelle Lookup-Maps für schnellen Zugriff auf Geräte nach UID
        let inputDeviceMap: [String: AudioDevice] = Dictionary(uniqueKeysWithValues: inputDevices.map { ($0.persistentUID, $0) })
        let outputDeviceMap: [String: AudioDevice] = Dictionary(uniqueKeysWithValues: outputDevices.map { ($0.persistentUID, $0) })

        print("🔍 Input devices in map:", inputDeviceMap.keys.count, "Output devices in map:", outputDeviceMap.keys.count)

        // Input: Durchlaufe Prioritätsliste von oben nach unten, finde erstes verbundenes Gerät
        var inputFound = false
        for (index, uid) in inputOrder.enumerated() {
            if let device = inputDeviceMap[uid] {
                print("🔍 Input[\(index)]: \(device.name) - connected: \(device.isConnected), isDefault: \(device.isDefault)")
                if device.isConnected {
                    if device.id != defaultInputID {
                        print("🎚 Switch input to:", device.name, "(Priority: \(index))")
                        AudioDeviceManager.shared.setDefaultInputDevice(device.id)
                        defaultInputID = device.id
                    } else {
                        print("✅ Input already set to:", device.name)
                    }
                    inputFound = true
                    break // Erstes verbundenes Gerät gefunden, stoppe Suche
                }
            } else {
                print("⚠️ Input[\(index)]: UID \(uid) not found in device map")
            }
        }
        if !inputFound {
            print("⚠️ No connected input device found in priority list")
        }

        // Output: Durchlaufe Prioritätsliste von oben nach unten, finde erstes verbundenes Gerät
        var outputFound = false
        for (index, uid) in outputOrder.enumerated() {
            if let device = outputDeviceMap[uid] {
                print("🔍 Output[\(index)]: \(device.name) - connected: \(device.isConnected), isDefault: \(device.isDefault)")
                if device.isConnected {
                    if device.id != defaultOutputID {
                        print("🔊 Switch output to:", device.name, "(Priority: \(index))")
                        AudioDeviceManager.shared.setDefaultOutputDevice(device.id)
                        defaultOutputID = device.id
                    } else {
                        print("✅ Output already set to:", device.name)
                    }
                    outputFound = true
                    break // Erstes verbundenes Gerät gefunden, stoppe Suche
                }
            } else {
                print("⚠️ Output[\(index)]: UID \(uid) not found in device map")
            }
        }
        if !outputFound {
            print("⚠️ No connected output device found in priority list")
        }
    }

    // MARK: - Profile Management
    
    func loadProfile(_ profile: Profile) {
        // Lädt Prioritäten aus Profil, aber wechselt nicht automatisch
        refresh()
    }
    
    func switchToProfile(_ profile: Profile) {
        // Wechselt Profil und aktiviert Geräte automatisch
        profileManager.setActiveProfile(profile)
        refresh()
        
        // Warte kurz, dann aktiviere Geräte
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.applyAutoSelection()
        }
    }
}
