import Foundation

struct ChatSession: Identifiable, Codable {
    let id: UUID
    var subject: String
    var messages: [Message]
    
    init(id: UUID = UUID(), subject: String, messages: [Message] = []) {
        self.id = id
        self.subject = subject
        self.messages = messages
    }
} 