import Foundation

class MessagePreprocessor {
    private let embeddings: EmbeddingsGenerator?
    
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
        
        // Try to generate embeddings - if successful, message is valid
        if let embeddings = self.embeddings {
            do {
                _ = try embeddings.generateEmbeddings(for: trimmed)
                return true
            } catch {
                print("⚠️ Embeddings error: \(error.localizedDescription)")
                // If embeddings fail, still allow the message to be processed
                return true
            }
        }
        
        // If no embeddings service, process all non-empty messages
        return true
    }
} 
