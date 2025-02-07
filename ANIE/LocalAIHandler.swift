import CoreML
import NaturalLanguage

class LocalAIHandler {
    private let cache = ResponseCache.shared
    
    func generateResponse(for query: String, sessionId: UUID) async throws -> String {
        // Only handle ML commands and persona queries
        let lowercasedQuery = query.lowercased()
        
        // Handle ML commands
        if lowercasedQuery.hasPrefix("!ml") {
            return handleMLCommand(query)
        }
        
        // Handle basic persona queries
        if isPersonaQuery(query) {
            return generatePersonaResponse(for: query)
        }
        
        // Return empty string for all other queries
        return ""
    }
    
    private func isPersonaQuery(_ query: String) -> Bool {
        let lowercasedQuery = query.lowercased()
        
        // Only match direct questions about ANIE's identity and creator
        let personaKeywords = [
            "who are you",
            "what are you",
            "tell me about yourself",
            "what does ANIE Stand for?",
            "what's your name",
            "what is your name",
            "who made you",
            "who created you",
            "who is your creator"
        ]
        
        return personaKeywords.contains { lowercasedQuery.contains($0) }
    }
    
    private func generatePersonaResponse(for query: String) -> String {
        let lowercasedQuery = query.lowercased()
        
        // Special handling for creator questions
        if lowercasedQuery.contains("who made you") || 
           lowercasedQuery.contains("who created you") ||
           lowercasedQuery.contains("who is your creator") {
            return "I was created by Todd Bruss, co-Founder of CodeFreeze.ai. Todd say's he an imaginative out of the box thinker. He is one of the crazy ones, and an absolute genius!"
        }
        
        // Default persona response for identity questions
        return """
        I am ANIE (Artificial Neural Intelligence Engine), a helpful AI assistant. \
        I use Apple's Neural Engine (ANE) through CoreML for BERT embeddings and semantic search. \
        I can help with a wide range of tasks while maintaining a professional yet approachable tone.
        """
    }
    
    private func handleMLCommand(_ command: String) -> String {
        // ML commands are handled by ChatManager
        return ""
    }
}

enum AIError: Error {
    case embeddingFailed
    case generationFailed
} 
