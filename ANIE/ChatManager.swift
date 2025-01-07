import Foundation
//import CoreML

protocol ChatGPTClient {
    func generateResponse(for message: String) async throws -> String
    func clearHistory()
}

class ChatManager {
    private let preprocessor: MessagePreprocessor
    private let cache: ResponseCache
    private let apiClient: ChatGPTClient
    
    init(preprocessor: MessagePreprocessor, cache: ResponseCache, apiClient: ChatGPTClient) {
        self.preprocessor = preprocessor
        self.cache = cache
        self.apiClient = apiClient
        
        // Print debug info on initialization
        print("=== ML System Configuration ===")
        MLDeviceCapabilities.debugComputeInfo()
        print("============================")
    }
    
    func processMessage(_ message: String) async throws -> String {
        if message.lowercased() == "!ml clear" {
            // Clear BERT cache
            cache.clearCache()
            // Clear conversation history
            apiClient.clearHistory()
            return """
            ✨ All caches cleared:
            • BERT response cache
            • Conversation history
            """
        }
        // Add command to check ML status
        if message.lowercased() == "!ml status" {
            let bertStats = EmbeddingsService.shared.getStats()
            let mlStats = """
            === ML System Status ===
            
            🧠 CoreML Status:
            • ANE Available: \(MLDeviceCapabilities.hasANE)
            • Compute Units: \(MLDeviceCapabilities.getOptimalComputeUnits())
            
            🤖 BERT Status:
            • Model Active: \(EmbeddingsService.shared.generator != nil)
            • Dimension: \(EmbeddingsService.shared.generator?.modelInfo()["embeddingDimension"] ?? 0)
            • Cache Operations: \(EmbeddingsService.shared.usageCount)
            • Using ANE: \(MLDeviceCapabilities.hasANE)
            
            💾 Cache Status:
            • Similarity Threshold: \(String(format: "%.2f", cache.threshold))
            • Cached Items: \(cache.getCacheSize())
            
            ========================
            """
            return mlStats
        }
        
        // First check if we need to process this message
        let shouldProcess = try preprocessor.shouldProcessMessage(message)
        
        // Only check cache for non-programming questions
        if preprocessor.shouldCache(message) {
            if let cachedResponse = try cache.findSimilarResponse(for: message) {
                print("🤖 Using BERT cache for response")
                return cachedResponse + "\n[Retrieved using BERT]"
            }
        } else {
            print("💭 Skipping cache for programming question")
        }
        
        print("💭 No cache hit, using ChatGPT")
        let response = try await apiClient.generateResponse(for: message)
        
        // Only cache non-programming responses
        if preprocessor.shouldCache(message) {
            try cache.cacheResponse(query: message, response: response)
        }
        
        return response
    }
    
    // Add a method to test ML performance
    func runMLPerformanceTest() async {
        print("\n=== ML Performance Test ===")
        let testMessages = [
            "Hello, how are you?",
            "What's the weather like today?",
            "Can you help me with a complex programming task?",
            "Tell me a joke",
            "Explain quantum computing"
        ]
        
        print("Testing preprocessing and embedding generation...")
        for message in testMessages {
            do {
                let start = CFAbsoluteTimeGetCurrent()
                let shouldProcess = try preprocessor.shouldProcessMessage(message)
                let end = CFAbsoluteTimeGetCurrent()
                print("Message: '\(message.prefix(20))...'")
                print("Should process: \(shouldProcess)")
                print("Processing time: \((end - start) * 1000)ms\n")
            } catch {
                print("Error processing message: \(error)")
            }
        }
        print("========================")
    }
} 
