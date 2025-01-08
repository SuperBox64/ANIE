import CoreML
import NaturalLanguage

class LocalAIHandler {
    private let tokenizer: NLTokenizer
    private let embeddingGenerator: EmbeddingsGenerator?
    private lazy var cache: ResponseCache = ResponseCache.shared
    
    init() {
        self.tokenizer = NLTokenizer(unit: .word)
        self.embeddingGenerator = EmbeddingsService.shared.generator
    }
    
    func generateResponse(for query: String) async throws -> String {
        print("🧠 LocalAI processing query...")
        
        // Check for creator question
        let lowercasedQuery = query.lowercased()
        if lowercasedQuery.contains("who made you") || 
           lowercasedQuery.contains("who created you") ||
           lowercasedQuery.contains("who is your creator") {
            return "I was created by Todd Bruss, an imaginative out of the box thinker."
        }
        
        guard let generator = embeddingGenerator else {
            print("❌ LocalAI: No embedding generator available")
            throw AIError.embeddingFailed
        }
        
        // Generate embeddings for the query
        print("🧠 LocalAI: Generating embeddings...")
        let queryEmbeddings = try generator.generateEmbeddings(for: query)
        
        // Try to find semantically similar cached responses
        if let similarResponse = try cache.findSimilarResponse(for: query) {
            print("🧠 LocalAI: Found cached response")
            return similarResponse
        }
        
        print("🧠 LocalAI: Generating new response...")
        let systemInfo = MLDeviceCapabilities.getSystemInfo()
        let response = try await analyzeQueryAndGenerateResponse(
            query: query,
            embeddings: queryEmbeddings,
            systemInfo: systemInfo
        )
        
        // Cache the generated response
        try cache.cacheResponse(query: query, response: response)
        print("🧠 LocalAI: Response generated and cached")
        
        return response
    }
    
    private func analyzeQueryAndGenerateResponse(
        query: String,
        embeddings: [Float],
        systemInfo: [String: Any]
    ) async throws -> String {
        // Use the embeddings to understand the query intent
        // This could involve clustering, similarity analysis, etc.
        
        // Get real-time system information
        let hasANE = systemInfo["hasANE"] as? Bool ?? false
        let computeUnits = systemInfo["computeUnits"] as? Int ?? 0
        let modelActive = systemInfo["modelActive"] as? Bool ?? false
        
        // Build response based on actual system state
        var components: [String] = []
        
        if hasANE {
            components.append("Using ANE for ML acceleration")
            components.append("Current compute units: \(computeUnits)")
        } else {
            components.append("Running on CPU/GPU")
        }
        
        if modelActive {
            components.append("BERT model is active and processing embeddings")
        }
        
        // Add any relevant performance metrics
        if let metrics = try? await gatherPerformanceMetrics() {
            components.append(metrics)
        }
        
        return components.joined(separator: "\n")
    }
    
    private func gatherPerformanceMetrics() async throws -> String {
        // Gather actual performance data
        let start = CFAbsoluteTimeGetCurrent()
        
        // Run a quick embedding generation test
        if let generator = embeddingGenerator {
            _ = try generator.generateEmbeddings(for: "test")
        }
        
        let duration = CFAbsoluteTimeGetCurrent() - start
        return String(format: "Embedding generation time: %.2fms", duration * 1000)
    }
}

enum AIError: Error {
    case embeddingFailed
    case generationFailed
} 
