import Foundation
import AppKit
import AudioToolbox

final class SoundFeedbackManager {
    static let shared = SoundFeedbackManager()
    
    private let store = SoundFeedbackStore.shared
    
    private init() {}
    
    enum SoundEvent {
        case profileSwitch
        case deviceSwitch
        case error
    }
    
    func playSound(for event: SoundEvent) {
        guard store.isEnabled() else { return }
        
        let soundName: String?
        switch event {
        case .profileSwitch:
            soundName = store.getProfileSwitchSound()
        case .deviceSwitch:
            soundName = store.getDeviceSwitchSound()
        case .error:
            soundName = store.getErrorSound()
        }
        
        guard let soundName = soundName, soundName != "none" else { return }
        
        if soundName == "system" {
            // System-Sound basierend auf Event
            let systemSoundName: String
            switch event {
            case .profileSwitch:
                systemSoundName = "Glass"
            case .deviceSwitch:
                systemSoundName = "Pop"
            case .error:
                systemSoundName = "Basso"
            }
            
            // Verwende NSSound für System-Sounds
            // Versuche zuerst mit dem System-Sound-Namen
            if let sound = NSSound(named: systemSoundName) {
                sound.volume = Float(store.getVolume()) / 100.0
                sound.play()
                print("🔊 SoundFeedbackManager: Spielt System-Sound '\(systemSoundName)' ab")
            } else {
                // Fallback: Verwende System-Beep mit AudioServicesPlaySystemSound
                // Das funktioniert auch wenn Audio-Geräte gerade wechseln
                AudioServicesPlaySystemSound(kSystemSoundID_UserPreferredAlert)
                print("🔊 SoundFeedbackManager: Fallback zu System-Beep")
            }
        } else {
            // Custom Sound (später erweiterbar)
            if let sound = NSSound(named: soundName) {
                sound.volume = Float(store.getVolume()) / 100.0
                sound.play()
            }
        }
    }
}


