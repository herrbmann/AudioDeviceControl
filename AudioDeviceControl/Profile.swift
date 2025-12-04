import Foundation

struct Profile: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var icon: String // Emoji
    var color: String // Hex-Farbe
    var inputOrder: [String] // Device UIDs
    var outputOrder: [String] // Device UIDs
    var ignoredInputUIDs: [String] // Ignorierte Input-Geräte für dieses Profil
    var ignoredOutputUIDs: [String] // Ignorierte Output-Geräte für dieses Profil
    var isDefault: Bool
    var wifiSSID: String? // Optional: WiFi-SSID für automatischen Wechsel
    
    init(id: UUID = UUID(),
         name: String,
         icon: String,
         color: String,
         inputOrder: [String] = [],
         outputOrder: [String] = [],
         ignoredInputUIDs: [String] = [],
         ignoredOutputUIDs: [String] = [],
         isDefault: Bool = false,
         wifiSSID: String? = nil) {
        self.id = id
        self.name = name
        self.icon = icon
        self.color = color
        self.inputOrder = inputOrder
        self.outputOrder = outputOrder
        self.ignoredInputUIDs = ignoredInputUIDs
        self.ignoredOutputUIDs = ignoredOutputUIDs
        self.isDefault = isDefault
        self.wifiSSID = wifiSSID
    }
    
    // MARK: - Codable mit Migration Support für fehlende Properties
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case icon
        case color
        case inputOrder
        case outputOrder
        case ignoredInputUIDs
        case ignoredOutputUIDs
        case isDefault
        case wifiSSID
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        icon = try container.decode(String.self, forKey: .icon)
        color = try container.decode(String.self, forKey: .color)
        inputOrder = try container.decodeIfPresent([String].self, forKey: .inputOrder) ?? []
        outputOrder = try container.decodeIfPresent([String].self, forKey: .outputOrder) ?? []
        // Neue Properties: Wenn nicht vorhanden, verwende leere Arrays (Migration)
        ignoredInputUIDs = try container.decodeIfPresent([String].self, forKey: .ignoredInputUIDs) ?? []
        ignoredOutputUIDs = try container.decodeIfPresent([String].self, forKey: .ignoredOutputUIDs) ?? []
        isDefault = try container.decodeIfPresent(Bool.self, forKey: .isDefault) ?? false
        wifiSSID = try container.decodeIfPresent(String.self, forKey: .wifiSSID)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(icon, forKey: .icon)
        try container.encode(color, forKey: .color)
        try container.encode(inputOrder, forKey: .inputOrder)
        try container.encode(outputOrder, forKey: .outputOrder)
        try container.encode(ignoredInputUIDs, forKey: .ignoredInputUIDs)
        try container.encode(ignoredOutputUIDs, forKey: .ignoredOutputUIDs)
        try container.encode(isDefault, forKey: .isDefault)
        try container.encodeIfPresent(wifiSSID, forKey: .wifiSSID)
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

