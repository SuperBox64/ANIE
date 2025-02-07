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
    private var currentSessionId: UUID?
    
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
    
    func setCurrentSession(_ sessionId: UUID) {
        self.currentSessionId = sessionId
    }
    
    func processMessage(_ message: String, isOmitted: Bool = false) async throws -> String {
        guard let sessionId = currentSessionId else {
            throw ChatError.noActiveSession
        }
        
        // If message is omitted, delete entire session cache
        if isOmitted {
            cache.deleteEntireSessionCache(for: sessionId)
            return "Message omitted"
        }
        
        // Handle ML commands first - these are ONLY handled by LocalAI
        if message.lowercased().hasPrefix("!ml") {
            return try await handleMLCommand(message.lowercased())
        }
        
        // Try LocalAI for persona queries
        let localResponse = try await localAI.generateResponse(for: message, sessionId: sessionId)
        if !localResponse.isEmpty {
            return localResponse + "\n[Using LocalAI]"
        }
        
        // For all other queries, try cache first
        if preprocessor.shouldCache(message) && !preprocessor.isMLRelatedQuery(message) && !isOmitted {
            do {
                if let cachedResponse = try cache.findSimilarResponse(for: message, sessionId: sessionId) {
                    return cachedResponse + "\n[Retrieved using BERT]"
                }
            } catch let error {
                // Log but continue - cache errors shouldn't block network request
                print("Cache error: \(error.localizedDescription)")
            }
        }
        
        // Finally try network
        do {
            let response = try await apiClient.generateResponse(for: message)
            
            // Cache if appropriate and not omitted
            if preprocessor.shouldCache(message) && !preprocessor.isMLRelatedQuery(message) && !isOmitted {
                do {
                    try cache.cacheResponse(query: message, response: response, sessionId: sessionId, isOmitted: isOmitted)
                } catch let error {
                    print("Cache error: \(error.localizedDescription)")
                }
            }
            
            return response
            
        } catch let error as NSError {
            if error.domain == NSURLErrorDomain && error.code == NSURLErrorNotConnectedToInternet {
                throw ChatError.networkError(error)
            }
            throw ChatError.networkError(error)
        }
    }
    
    // Add a method to test ML performance
    func runMLPerformanceTest() async -> String {
        var results = ["=== ML Performance Test ===\n"]
        let testMessages = [
            "Hello, how are you?",
            "What's the weather like today?",
            "Can you help me with a complex programming task?",
            "Tell me a joke",
            "Explain quantum computing"
        ]
        
        // Test BERT embeddings performance
        results.append("🧮 BERT Embeddings Performance:")
        if let generator = EmbeddingsService.shared.generator {
            let start = CFAbsoluteTimeGetCurrent()
            for message in testMessages {
                do {
                    _ = try await generator.generateEmbeddings(for: message)
                } catch {
                    results.append("• Error: \(error.localizedDescription)")
                }
            }
            let end = CFAbsoluteTimeGetCurrent()
            let avgTime = (end - start) * 1000 / Double(testMessages.count)
            results.append("• Average embedding time: \(String(format: "%.2f", avgTime))ms")
            results.append("• Using ANE: \(MLDeviceCapabilities.hasANE)")
            results.append("• Compute Units: \(MLDeviceCapabilities.getOptimalComputeUnits())")
        } else {
            results.append("• BERT model not loaded")
        }
        
        // Test cache performance
        results.append("\n💾 Cache Performance:")
        let cacheSize = cache.getCacheSize()
        results.append("• Total cached items: \(cacheSize)")
        results.append("• Similarity threshold: \(String(format: "%.2f", cache.threshold))")
        
        let start = CFAbsoluteTimeGetCurrent()
        for message in testMessages {
            if let sessionId = currentSessionId {
                do {
                    _ = try cache.findSimilarResponse(for: message, sessionId: sessionId)
                } catch {
                    // Ignore errors in test
                }
            }
        }
        let end = CFAbsoluteTimeGetCurrent()
        let avgSearchTime = (end - start) * 1000 / Double(testMessages.count)
        results.append("• Average search time: \(String(format: "%.2f", avgSearchTime))ms")
        
        // Test preprocessing performance
        results.append("\n⚡️ Preprocessing Performance:")
        var totalTime: Double = 0
        for message in testMessages {
            let start = CFAbsoluteTimeGetCurrent()
            _ = preprocessor.shouldCache(message)
            let end = CFAbsoluteTimeGetCurrent()
            totalTime += (end - start)
        }
        let avgPreprocessTime = totalTime * 1000 / Double(testMessages.count)
        results.append("• Average preprocess time: \(String(format: "%.2f", avgPreprocessTime))ms")
        
        // Test LocalAI performance
        results.append("\n🧠 LocalAI Performance:")
        if let sessionId = currentSessionId {
            let start = CFAbsoluteTimeGetCurrent()
            do {
                _ = try await localAI.generateResponse(for: testMessages[0], sessionId: sessionId)
                let end = CFAbsoluteTimeGetCurrent()
                results.append("• Response time: \(String(format: "%.2f", (end - start) * 1000))ms")
            } catch {
                results.append("• Error: \(error.localizedDescription)")
            }
        }
        
        results.append("\n=== End of Performance Test ===")
        return results.joined(separator: "\n")
    }
    
    private func handleMLCommand(_ command: String) async throws -> String {
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
        case "!ml perf":
            // Run performance test and return results directly
            return await runMLPerformanceTest()
            
        case "!ml", "!ml help":  // Handle both !ml and !ml help the same way
            return """
            🤖 ANIE ML Commands:
            
            !ml status
            !ml clear
            !ml bert
            !ml cache 
            !ml perf
            !ml help
            
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
            
        case "!ml bert":
            return """
            === BERT Model Information ===
            
            📊 Model Configuration:
            • Status: \(EmbeddingsService.shared.generator != nil ? "Active" : "Inactive")
            • Type: DistilBERT Base Uncased
            • Tokenizer: WordPiece
            • Max Sequence Length: 512
            
            🧮 Embeddings:
            • Dimension: \(EmbeddingsService.shared.generator?.modelInfo()["embeddingDimension"] ?? 0)
            • Total Operations: \(EmbeddingsService.shared.usageCount)
            • Using ANE: \(MLDeviceCapabilities.hasANE)
            
            ⚡️ Performance:
            • Compute Units: \(MLDeviceCapabilities.getOptimalComputeUnits())
            • Average Latency: \(String(format: "%.2f", EmbeddingsService.shared.generator?.modelInfo()["averageLatency"] as? Double ?? 0.0))ms
            
            ========================
            """
            
        default:
            return "Unknown ML command. Use !ml help to see available commands."
        }
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
