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
    
    init(preprocessor: MessagePreprocessor, apiClient: ChatGPTClient) {
        self.preprocessor = preprocessor
        self.cache = ResponseCache.shared
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
        
        // Local AI mode - all processing happens locally
        if useLocalAI {
            await MainActor.run {
                print("🧠 Using LocalAI for query: \(message)")
            }
            let response = try await localAI.generateResponse(for: message)
            await MainActor.run {
                print("🧠 LocalAI generated response")
            }
            return response + "\n[Using LocalAI]"
        }
        
        // Regular processing flow when LocalAI is disabled
        do {
            // Try cache first
            if preprocessor.shouldCache(message) && !preprocessor.isMLRelatedQuery(message) {
                await MainActor.run {
                    print("🔍 Checking cache for: \(message)")
                }
                if let cachedResponse = try cache.findSimilarResponse(for: message) {
                    await MainActor.run {
                        print("✨ Cache hit! Using cached response")
                    }
                    return cachedResponse + "\n[Retrieved using BERT]"
                }
                await MainActor.run {
                    print("💫 No cache hit, generating new response")
                }
            }
            
            // Try API
            let response = try await apiClient.generateResponse(for: message)
            
            // Cache if appropriate
            if preprocessor.shouldCache(message) && !preprocessor.isMLRelatedQuery(message) {
                try cache.cacheResponse(query: message, response: response)
                await MainActor.run {
                    print("📥 Cached new response")
                }
            }
            
            return response
            
        } catch let error as NSError {
            // If network is offline, fallback to local AI
            if error.domain == NSURLErrorDomain && error.code == NSURLErrorNotConnectedToInternet {
                await MainActor.run {
                    print("🌐 Network offline, falling back to Local AI")
                }
                let response = try await localAI.generateResponse(for: message)
                return response + "\n[Using LocalAI - Network Offline]"
            }
            throw error
        }
    }
    
    private func handleMLCommand(_ command: String) -> String {
        // Clean up command by:
        // 1. Trimming whitespace and newlines
        // 2. Converting to lowercase
        // 3. Removing extra spaces
        let cleanCommand = command
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        
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
            
        case "!ml cache":
            return """
            === Cache System Status ===
            
            📊 Cache Configuration:
            • Total Cached Items: \(cache.getCacheSize())
            • Similarity Threshold: \(String(format: "%.2f", cache.threshold))
            • Storage Type: Persistent (UserDefaults)
            
            🤖 BERT Integration:
            • Model Status: \(EmbeddingsService.shared.generator != nil ? "Active" : "Inactive")
            • Total Operations: \(EmbeddingsService.shared.usageCount)
            • Vector Dimension: \(EmbeddingsService.shared.generator?.modelInfo()["embeddingDimension"] ?? 0)
            
            ⚙️ Cache Behavior:
            • Skips ML/AI Queries: Yes
            • Skips Programming Queries: Yes
            • Uses Semantic Search: Yes
            • Word Overlap Required: 70%
            
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
