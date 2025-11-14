import Foundation
import CoreAudio

final class DeviceWatcher {

    static let shared = DeviceWatcher()

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
            AudioState.shared.refresh()
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
    }
}
