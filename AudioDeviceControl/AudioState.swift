import Foundation
import CoreAudio
import Combine

final class AudioState: ObservableObject {

    static let shared = AudioState()

    @Published var inputDevices: [AudioDevice] = []
    @Published var outputDevices: [AudioDevice] = []

    @Published var defaultInputID: AudioDeviceID = 0
    @Published var defaultOutputID: AudioDeviceID = 0

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

        // Priorität aus Store laden
        let inputOrder  = PriorityStore.shared.loadInputOrder()
        let outputOrder = PriorityStore.shared.loadOutputOrder()

        // Sortieren (inkl. Offline-Platzhalter für bekannte Geräte)
        inputDevices  = applyPriority(devices: inputs, storedUIDs: inputOrder)
        outputDevices = applyPriority(devices: outputs, storedUIDs: outputOrder)

        // Ergänze bekannte, aktuell nicht sichtbare Geräte
        inputDevices  = appendOfflineKnownDevices(current: inputDevices,  order: inputOrder,  wantInput: true)
        outputDevices = appendOfflineKnownDevices(current: outputDevices, order: outputOrder, wantInput: false)

        print("📌 INPUT Devices:", inputDevices.map { $0.name })
        print("📌 OUTPUT Devices:", outputDevices.map { $0.name })

        applyAutoSelection()
    }

    // MARK: Update Priority from UI

    func updateInputOrder(_ devices: [AudioDevice]) {
        let uids = devices.map { $0.persistentUID }
        PriorityStore.shared.saveInputOrder(uids)
        refresh()
    }

    func updateOutputOrder(_ devices: [AudioDevice]) {
        let uids = devices.map { $0.persistentUID }
        PriorityStore.shared.saveOutputOrder(uids)
        refresh()
    }

    // MARK: Priority Logic

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
}
