import Foundation
import CoreAudio

final class DeviceWatcher {

    static let shared = DeviceWatcher()
    
    private var pendingRefresh: DispatchWorkItem?
    private let debounceInterval: TimeInterval = 0.15

    private func scheduleRefresh() {
        pendingRefresh?.cancel()
        let work = DispatchWorkItem { [weak self] in
            DispatchQueue.main.async {
                AudioState.shared.refresh()
            }
        }
        pendingRefresh = work
        DispatchQueue.main.asyncAfter(deadline: .now() + debounceInterval, execute: work)
    }

    private init() {
        startListening()
    }

    private func startListening() {

        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        let systemObject = AudioObjectID(kAudioObjectSystemObject)

        // Listener ohne Rückgabewert!
        let callback: AudioObjectPropertyListenerBlock = { _, _ in
            print("🔔 DeviceWatcher: devices changed")
            self.scheduleRefresh()
            // ❌ Kein return noErr → der Closure hat return Void
        }

        let status = AudioObjectAddPropertyListenerBlock(
            systemObject,
            &address,
            DispatchQueue.main,
            callback
        )

        if status != noErr {
            print("❌ DeviceWatcher Error:", status)
        }
        
        // Listen for default input device changes
        var defInAddr = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        let statusIn = AudioObjectAddPropertyListenerBlock(
            systemObject,
            &defInAddr,
            DispatchQueue.main
        ) { _, _ in
            print("🔔 DeviceWatcher: default input changed")
            self.scheduleRefresh()
        }

        if statusIn != noErr {
            print("❌ DeviceWatcher DefaultInput Error:", statusIn)
        }

        // Listen for default output device changes
        var defOutAddr = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        let statusOut = AudioObjectAddPropertyListenerBlock(
            systemObject,
            &defOutAddr,
            DispatchQueue.main
        ) { _, _ in
            print("🔔 DeviceWatcher: default output changed")
            self.scheduleRefresh()
        }

        if statusOut != noErr {
            print("❌ DeviceWatcher DefaultOutput Error:", statusOut)
        }
    }
}

