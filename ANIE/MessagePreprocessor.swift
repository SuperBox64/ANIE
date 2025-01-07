import Foundation

class MessagePreprocessor {
    private let embeddings: EmbeddingsGenerator?
    private let programmingKeywords = Set([
        "code", "programming", "function", "class", "variable",
        "python", "javascript", "java", "swift", "rust", "c++",
        "debug", "compiler", "syntax", "algorithm", "api",
        "framework", "library", "code review", "git", "database"
    ])
    
    init() {
        self.embeddings = EmbeddingsService.shared.generator
    }
    
    func shouldProcessMessage(_ message: String) throws -> Bool {
        // Basic validation
        let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return false
        }
        
        // Always process messages that are commands
        if trimmed.hasPrefix("!") {
            return true
        }
        
        return true
    }
    
    func shouldCache(_ message: String) -> Bool {
        let lowercased = message.lowercased()
        
        // Check if message contains programming keywords
        for keyword in programmingKeywords {
            if lowercased.contains(keyword) {
                print("🚫 Skipping cache for programming question: '\(message.prefix(30))...'")
                return false
            }
        }
        
        return true
    }
} 
