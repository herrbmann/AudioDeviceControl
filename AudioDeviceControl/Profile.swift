import Foundation

struct Profile: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var icon: String // Emoji
    var color: String // Hex-Farbe
    var inputOrder: [String] // Device UIDs
    var outputOrder: [String] // Device UIDs
    var isDefault: Bool
    
    init(id: UUID = UUID(),
         name: String,
         icon: String,
         color: String,
         inputOrder: [String] = [],
         outputOrder: [String] = [],
         isDefault: Bool = false) {
        self.id = id
        self.name = name
        self.icon = icon
        self.color = color
        self.inputOrder = inputOrder
        self.outputOrder = outputOrder
        self.isDefault = isDefault
    }
}

// Preset-Farben für Profile
struct ProfileColorPreset {
    static let colors: [(name: String, hex: String)] = [
        ("Blau", "#007AFF"),
        ("Grün", "#34C759"),
        ("Rot", "#FF3B30"),
        ("Orange", "#FF9500"),
        ("Lila", "#AF52DE"),
        ("Pink", "#FF2D55"),
        ("Gelb", "#FFCC00"),
        ("Türkis", "#5AC8FA"),
        ("Indigo", "#5856D6"),
        ("Braun", "#A2845E"),
        ("Grau", "#8E8E93"),
        ("Schwarz", "#000000")
    ]
    
    static func hexToColor(_ hex: String) -> (r: Double, g: Double, b: Double) {
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
        return (Double(r) / 255.0, Double(g) / 255.0, Double(b) / 255.0)
    }
}

// Häufig verwendete Emojis für Profile
struct ProfileEmojiPreset {
    static let emojis: [String] = [
        "🏠", // Home
        "💼", // Work
        "🎮", // Gaming
        "🖥️", // Desktop
        "💻", // Laptop
        "🎧", // Headphones
        "🎤", // Microphone
        "🔊", // Speaker
        "🎵", // Music
        "🌍"  // General/Travel/Remote
    ]
}

