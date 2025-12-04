import Foundation
import CoreAudio
import Combine

final class AudioState: ObservableObject {

    static let shared = AudioState()

    @Published var inputDevices: [AudioDevice] = []
    @Published var outputDevices: [AudioDevice] = []
    @Published var showIgnored: Bool = false

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
        
        // Ignored Devices sind jetzt pro Profil
        let ignoredInputUIDs: [String]
        let ignoredOutputUIDs: [String]
        
        if let activeProfile = profileManager.activeProfile {
            ignoredInputUIDs = activeProfile.ignoredInputUIDs
            ignoredOutputUIDs = activeProfile.ignoredOutputUIDs
        } else {
            // Fallback: Leere Listen wenn kein Profil aktiv
            ignoredInputUIDs = []
            ignoredOutputUIDs = []
        }
        
        let ignoredInput = Set(ignoredInputUIDs)
        let ignoredOutput = Set(ignoredOutputUIDs)
        let deletedUIDs = PriorityStore.shared.loadDeletedUIDs()
        let deleted = Set(deletedUIDs)

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

            // Skip ignored/deleted devices unless showIgnored is enabled
            if !showIgnored {
                let isIgnored = (device.isInput && ignoredInput.contains(device.persistentUID)) ||
                               (device.isOutput && ignoredOutput.contains(device.persistentUID))
                if isIgnored || deleted.contains(device.persistentUID) {
                    continue
                }
            }

            if device.isInput { inputs.append(device) }
            if device.isOutput { outputs.append(device) }
        }

        // Register currently visible devices (store metadata for offline rendering)
        DeviceRegistry.shared.registerDevices(inputs + outputs)

        // Build lists strictly following stored priority order.
        // Missing devices are shown as offline placeholders at their original positions.
        let newInputDevices  = buildDeviceList(devices: inputs, storedUIDs: inputOrder, wantInput: true, ignoredInput: ignoredInput, ignoredOutput: ignoredOutput, deleted: deleted)
        let newOutputDevices = buildDeviceList(devices: outputs, storedUIDs: outputOrder, wantInput: false, ignoredInput: ignoredInput, ignoredOutput: ignoredOutput, deleted: deleted)

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
                                 ignoredInput: Set<String>,
                                 ignoredOutput: Set<String>,
                                 deleted: Set<String>) -> [AudioDevice] {
        var result: [AudioDevice] = []

        // Fast lookup for currently present devices by UID
        let presentByUID: [String: AudioDevice] = Dictionary(uniqueKeysWithValues: devices.map { ($0.persistentUID, $0) })

        // 1) Place all stored UIDs in exact order, using present device or offline placeholder
        // ABER: Ignoriere ignorierte und gelöschte Geräte
        for uid in storedUIDs {
            // Überspringe ignorierte und gelöschte Geräte
            let isIgnored = (wantInput && ignoredInput.contains(uid)) || (!wantInput && ignoredOutput.contains(uid))
            if isIgnored || deleted.contains(uid) {
                continue
            }
            
            if let dev = presentByUID[uid] {
                result.append(dev)
            } else if let meta = DeviceRegistry.shared.metadata(for: uid) {
                // Only include if it matches the desired direction
                if (wantInput && meta.isInput) || (!wantInput && meta.isOutput) {
                    let placeholder = AudioDeviceFactory.makeOffline(uid: uid,
                                                                     name: meta.name,
                                                                     isInput: meta.isInput,
                                                                     isOutput: meta.isOutput)
                    result.append(placeholder)
                }
            }
        }

        // 2) Append any currently present devices that are not yet in stored order (new devices)
        // ABER: Ignoriere ignorierte und gelöschte Geräte
        for dev in devices {
            if !result.contains(where: { $0.persistentUID == dev.persistentUID }) {
                let isIgnored = (wantInput && ignoredInput.contains(dev.persistentUID)) || (!wantInput && ignoredOutput.contains(dev.persistentUID))
                if !isIgnored && !deleted.contains(dev.persistentUID) {
                    result.append(dev)
                }
            }
        }

        // 3) Optionally append any other known devices (not in order, not present) as offline placeholders
        // ABER: Ignoriere ignorierte und gelöschte Geräte
        let knownUIDs = DeviceRegistry.shared.storedUIDs
        for uid in knownUIDs where !result.contains(where: { $0.persistentUID == uid }) {
            // Überspringe ignorierte und gelöschte Geräte
            let isIgnored = (wantInput && ignoredInput.contains(uid)) || (!wantInput && ignoredOutput.contains(uid))
            if isIgnored || deleted.contains(uid) {
                continue
            }
            
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

        // Filter out ignored/deleted devices unless showIgnored is true
        if !showIgnored {
            result.removeAll { device in
                let isIgnored = (wantInput && ignoredInput.contains(device.persistentUID)) || (!wantInput && ignoredOutput.contains(device.persistentUID))
                return isIgnored || deleted.contains(device.persistentUID)
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

        if let topInput = inputDevices.first(where: { $0.isConnected }) {
            if topInput.id != defaultInputID {
                print("🎚 Switch input to:", topInput.name)
                AudioDeviceManager.shared.setDefaultInputDevice(topInput.id)
                defaultInputID = topInput.id
            }
        }

        if let topOutput = outputDevices.first(where: { $0.isConnected }) {
            if topOutput.id != defaultOutputID {
                print("🔊 Switch output to:", topOutput.name)
                AudioDeviceManager.shared.setDefaultOutputDevice(topOutput.id)
                defaultOutputID = topOutput.id
            }
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
