import SwiftUI

struct DevicePriorityMiniMap: View {
    let activeOutputDevice: AudioDevice?
    let activeInputDevice: AudioDevice?
    let isProfileActive: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            if let output = activeOutputDevice {
                HStack(spacing: 4) {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: 9))
                        .foregroundColor(iconColor)
                    Text(output.name)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            if let input = activeInputDevice {
                HStack(spacing: 4) {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 9))
                        .foregroundColor(iconColor)
                    Text(input.name)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            if activeOutputDevice == nil && activeInputDevice == nil {
                Text("Keine aktiven Geräte")
                    .font(.caption2)
                    .foregroundColor(.secondary.opacity(0.6))
            }
        }
    }
    
    private var iconColor: Color {
        if isProfileActive {
            return .green
        } else {
            return .secondary.opacity(0.6)
        }
    }
}

