import Foundation

struct Message: Identifiable, Codable, Equatable {
    let id: UUID
    let content: String
    let isUser: Bool
    let timestamp: Date
    let usedBERT: Bool
    
    init(id: UUID = UUID(), content: String, isUser: Bool, timestamp: Date = Date(), usedBERT: Bool = false) {
        self.id = id
        self.content = content
        self.isUser = isUser
        self.timestamp = timestamp
        self.usedBERT = usedBERT
    }
    
    // Coding keys
    enum CodingKeys: String, CodingKey {
        case id
        case content
        case isUser
        case timestamp
        case usedBERT
    }
    
    // Implement custom decoding
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        content = try container.decode(String.self, forKey: .content)
        isUser = try container.decode(Bool.self, forKey: .isUser)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        // Provide default value for usedBERT if it doesn't exist in older saved data
        usedBERT = try container.decodeIfPresent(Bool.self, forKey: .usedBERT) ?? false
    }
    
    // Implement custom encoding
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(content, forKey: .content)
        try container.encode(isUser, forKey: .isUser)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(usedBERT, forKey: .usedBERT)
    }
    
    // Equatable conformance
    static func == (lhs: Message, rhs: Message) -> Bool {
        lhs.id == rhs.id &&
        lhs.content == rhs.content &&
        lhs.isUser == rhs.isUser &&
        lhs.timestamp == rhs.timestamp &&
        lhs.usedBERT == rhs.usedBERT
    }
} 