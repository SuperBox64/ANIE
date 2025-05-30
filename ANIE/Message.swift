import Foundation

struct Message: Identifiable, Codable, Equatable {
    let id: UUID
    let content: String
    let isUser: Bool
    let timestamp: Date
    let usedBERT: Bool
    let usedLocalAI: Bool
    let imageData: Data?
    let isError: Bool
    var isOmitted: Bool
    
    init(id: UUID = UUID(), content: String, isUser: Bool, timestamp: Date = Date(), usedBERT: Bool = false, usedLocalAI: Bool = false, imageData: Data? = nil, isError: Bool = false, isOmitted: Bool = false) {
        self.id = id
        self.content = content
        self.isUser = isUser
        self.timestamp = timestamp
        self.usedBERT = usedBERT
        self.usedLocalAI = usedLocalAI
        self.imageData = imageData
        self.isError = isError
        self.isOmitted = isOmitted
    }
    
    // Coding keys
    enum CodingKeys: String, CodingKey {
        case id
        case content
        case isUser
        case timestamp
        case usedBERT
        case usedLocalAI
        case imageData
        case isError
        case isOmitted
    }
    
    // Implement custom decoding
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        content = try container.decode(String.self, forKey: .content)
        isUser = try container.decode(Bool.self, forKey: .isUser)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        usedBERT = try container.decodeIfPresent(Bool.self, forKey: .usedBERT) ?? false
        usedLocalAI = try container.decodeIfPresent(Bool.self, forKey: .usedLocalAI) ?? false
        imageData = try container.decodeIfPresent(Data.self, forKey: .imageData)
        isError = try container.decodeIfPresent(Bool.self, forKey: .isError) ?? false
        isOmitted = try container.decodeIfPresent(Bool.self, forKey: .isOmitted) ?? false
    }
    
    // Implement custom encoding
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(content, forKey: .content)
        try container.encode(isUser, forKey: .isUser)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(usedBERT, forKey: .usedBERT)
        try container.encode(usedLocalAI, forKey: .usedLocalAI)
        try container.encodeIfPresent(imageData, forKey: .imageData)
        try container.encode(isError, forKey: .isError)
        try container.encode(isOmitted, forKey: .isOmitted)
    }
    
    // Equatable conformance
    static func == (lhs: Message, rhs: Message) -> Bool {
        lhs.id == rhs.id &&
        lhs.content == rhs.content &&
        lhs.isUser == rhs.isUser &&
        lhs.timestamp == rhs.timestamp &&
        lhs.usedBERT == rhs.usedBERT &&
        lhs.usedLocalAI == rhs.usedLocalAI &&
        lhs.imageData == rhs.imageData &&
        lhs.isError == rhs.isError &&
        lhs.isOmitted == rhs.isOmitted
    }
} 