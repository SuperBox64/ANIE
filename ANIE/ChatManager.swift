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
    private let localAI: LocalAIHandler
    
    init(preprocessor: MessagePreprocessor, cache: ResponseCache, apiClient: ChatGPTClient) {
        self.preprocessor = preprocessor
        self.cache = cache
        self.apiClient = apiClient
        self.localAI = LocalAIHandler()
        
        // Print debug info on initialization
        print("=== ML System Configuration ===")
        MLDeviceCapabilities.debugComputeInfo()
        print("============================")
    }
    
    func processMessage(_ message: String) async throws -> String {
        // Handle ML commands first
        if message.lowercased().hasPrefix("!ml") {
            return handleMLCommand(message.lowercased())
        }
        
        let useLocalAI = UserDefaults.standard.bool(forKey: "useLocalAI")
        
        // Check if we should use local processing
        if useLocalAI && preprocessor.isMLRelatedQuery(message) {
            print("📝 Using Local AI for query: \(message)")
            let response = try await localAI.generateResponse(for: message)
            return response
        }
        
        // Regular processing flow - skip cache if Local AI is enabled
        if !useLocalAI && preprocessor.shouldCache(message) {
            print("🔍 Checking cache for: \(message)")
            if let cachedResponse = try cache.findSimilarResponse(for: message) {
                print("✨ Cache hit! Using cached response")
                let response = cachedResponse + "\n[Retrieved using BERT]"
                return response
            }
            print("💫 No cache hit, generating new response")
            
            // Generate new response and cache it
            let response = try await apiClient.generateResponse(for: message)
            try cache.cacheResponse(query: message, response: response)
            print("📥 Cached new response")
            return response
        } else {
            if useLocalAI {
                print("⚠️ Local AI enabled - skipping cache")
            } else {
                print("⚠️ Message not eligible for caching")
            }
        }
        
        let response = try await apiClient.generateResponse(for: message)
        return response
    }
    
    private func handleMLCommand(_ command: String) -> String {
        // Trim any whitespace and make lowercase for consistent comparison
        let cleanCommand = command.trimmingCharacters(in: .whitespaces).lowercased()
        
        switch cleanCommand {
        case "!ml", "!ml help":  // Handle both !ml and !ml help the same way
            return """
            🤖 ANIE ML Commands:
            
            !ml status  - Show ML system status including:
            • CoreML/ANE status
            • BERT model status
            • Cache statistics
            
            !ml clear   - Clear all caches:
            • BERT response cache
            • Conversation history
            • Persisted data
            
            !ml help    - Show this help message
            
            Note: BERT caching is automatically disabled for programming questions.
            Current similarity threshold: \(String(format: "%.2f", cache.threshold))
            """
            
        case "!ml clear":
            // Clear BERT cache
            cache.clearCache()
            // Clear conversation history
            apiClient.clearHistory()
            // Clear UserDefaults
            UserDefaults.standard.synchronize()
            
            return """
            ✨ All caches cleared:
            • BERT response cache
            • Conversation history
            • Persisted data
            """
            
        case "!ml status":
            return """
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
            
        default:
            return "Unknown ML command. Use !ml help to see available commands."
        }
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

// Add to MLDeviceCapabilities
extension MLDeviceCapabilities {
    static func getSystemInfo() -> [String: Any] {
        return [
            "hasANE": hasANE,
            "computeUnits": getOptimalComputeUnits(),
            "modelActive": EmbeddingsService.shared.generator != nil,
            "usageCount": EmbeddingsService.shared.usageCount
        ]
    }
} 
