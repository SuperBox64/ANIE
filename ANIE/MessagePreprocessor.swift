import Foundation

class MessagePreprocessor {
    private let embeddings: EmbeddingsGenerator?
    private let programmingKeywords = Set([
        "code", "programming", "function", "class", "variable",
        "python", "javascript", "java", "swift", "rust", "c++",
        "debug", "compiler", "syntax", "algorithm", "api",
        "framework", "library", "code review", "git", "database"
    ])
    private let mlKeywords = [
        "ane",
        "apple neural engine", 
        "neural engine",
        "bert",
        "coreml",
        "ml",
        "machine learning",
        "embeddings"
    ]
    
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
        
        // Skip caching for ML-related queries
        if mlKeywords.contains(where: { lowercased.contains($0) }) {
            return false
        }
        
        // Skip caching for programming questions (existing logic)
        if message.contains("{") || message.contains("}") ||
           message.contains("func ") || message.contains("class ") ||
           message.contains("struct ") || message.contains("import ") {
            return false
        }
        
        return true
    }
} 
