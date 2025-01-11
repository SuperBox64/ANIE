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
    
    func generateResponse(for query: String, sessionId: UUID) async throws -> String {
        print("🧠 LocalAI processing query...")
        
        // Check for special queries first
        if let specialResponse = handleSpecialQueries(query) {
            return specialResponse
        }
        
        // Try to find a cached response only for non-programming, non-AI/ML queries
        let lowercasedQuery = query.lowercased()
        let isProgrammingQuery = lowercasedQuery.contains("code") || 
                               lowercasedQuery.contains("programming") || 
                               lowercasedQuery.contains("swift") || 
                               lowercasedQuery.contains("function") ||
                               lowercasedQuery.contains("class") ||
                               lowercasedQuery.contains("struct")
        
        let isAIMLQuery = lowercasedQuery.contains("ai") ||
                         lowercasedQuery.contains("ml") ||
                         lowercasedQuery.contains("neural") ||
                         lowercasedQuery.contains("bert") ||
                         lowercasedQuery.contains("model")
        
        if !isProgrammingQuery && !isAIMLQuery {
            do {
                if let similarResponse = try cache.findSimilarResponse(for: query, sessionId: sessionId) {
                    print("🧠 LocalAI: Found cached response")
                    return similarResponse
                }
            } catch {
                print("🧠 LocalAI: Cache lookup failed, continuing with local response")
            }
        } else {
            print("🧠 LocalAI: Skipping cache for programming/AI/ML query")
        }
        
        // Generate a local response based on the query type
        let response = generateLocalResponse(for: query)
        
        // Cache all responses that aren't programming or AI/ML related
        if !isProgrammingQuery && !isAIMLQuery {
            do {
                try cache.cacheResponse(query: query, response: response, sessionId: sessionId)
                print("🧠 LocalAI: Cached response")
            } catch {
                print("🧠 LocalAI: Failed to cache response: \(error)")
            }
        } else {
            print("🧠 LocalAI: Response not cached - Programming/AI/ML query")
        }
        
        return response
    }
    
    private func handleSpecialQueries(_ query: String) -> String? {
        let lowercasedQuery = query.lowercased()
        
        // Creator/About queries
        if lowercasedQuery.contains("who made you") || 
           lowercasedQuery.contains("who created you") ||
           lowercasedQuery.contains("who is your creator") {
            return "I was created by Todd Bruss, an imaginative out of the box thinker."
        }
        
        // System capabilities
        if lowercasedQuery.contains("what can you do") ||
           lowercasedQuery.contains("your capabilities") ||
           lowercasedQuery.contains("help me") {
            return """
                I am ANIE (Artificial Neural Intelligence Engine), and I can help you with:
                - Answering questions about ML and AI
                - Providing information about the Apple Neural Engine
                - Explaining technical concepts
                - Basic calculations and analysis
                - Offering suggestions and recommendations
                
                I'm currently running in Local AI mode, which means I operate without network connectivity.
                """
        }
        
        // ML/AI specific queries
        if lowercasedQuery.contains("neural engine") ||
           lowercasedQuery.contains("ane") ||
           lowercasedQuery.contains("ml") ||
           lowercasedQuery.contains("bert") {
            let systemInfo = MLDeviceCapabilities.getSystemInfo()
            return generateMLResponse(query: lowercasedQuery, systemInfo: systemInfo)
        }
        
        return nil
    }
    
    private func generateLocalResponse(for query: String) -> String {
        let lowercasedQuery = query.lowercased()
        
        // Swift programming specific responses
        if lowercasedQuery.contains("swift") {
            if lowercasedQuery.contains("swiftui") {
                return LocalAIResponses.Programming.swiftUI
            }
            if lowercasedQuery.contains("concurrency") || lowercasedQuery.contains("async") {
                return LocalAIResponses.Programming.concurrency
            }
            if lowercasedQuery.contains("test") {
                return LocalAIResponses.Programming.testing
            }
            if lowercasedQuery.contains("pattern") || lowercasedQuery.contains("mvvm") {
                return LocalAIResponses.Programming.patterns
            }
        }
        
        // System information queries
        if lowercasedQuery.contains("hardware") || lowercasedQuery.contains("performance") {
            return LocalAIResponses.SystemInfo.hardware()
        }
        
        if lowercasedQuery.contains("cache") || lowercasedQuery.contains("memory") {
            return LocalAIResponses.SystemInfo.cache()
        }
        
        if lowercasedQuery.contains("ml") || lowercasedQuery.contains("capabilities") {
            return LocalAIResponses.SystemInfo.mlCapabilities()
        }
        
        // Technical knowledge queries
        if lowercasedQuery.contains("neural") || lowercasedQuery.contains("network") {
            return LocalAIResponses.Technical.neuralNetworks()
        }
        
        if lowercasedQuery.contains("machine learning") || lowercasedQuery.contains("ml") {
            return LocalAIResponses.Technical.machineLearning()
        }
        
        if lowercasedQuery.contains("system") || lowercasedQuery.contains("architecture") {
            return LocalAIResponses.Technical.architecture()
        }
        
        // Default response
        return LocalAIResponses.Static.defaultCapabilities
    }
    
    private func generateMLResponse(query: String, systemInfo: [String: Any]) -> String {
        let hasANE = systemInfo["hasANE"] as? Bool ?? false
        let computeUnits = systemInfo["computeUnits"] as? Int ?? 0
        let modelActive = systemInfo["modelActive"] as? Bool ?? false
        
        var components = [String]()
        
        if hasANE {
            components.append("The Apple Neural Engine (ANE) is active and being used for ML acceleration")
            components.append("Current compute units: \(computeUnits)")
        } else {
            components.append("Running on CPU/GPU for ML computations")
        }
        
        if modelActive {
            components.append("BERT model is active and ready for embedding generation")
        }
        
        if let metrics = try? gatherPerformanceMetrics() {
            components.append(metrics)
        }
        
        return components.joined(separator: "\n")
    }
    
    private func gatherPerformanceMetrics() throws -> String {
        let start = CFAbsoluteTimeGetCurrent()
        
        if let generator = embeddingGenerator {
            _ = try generator.generateEmbeddings(for: "test")
        }
        
        let duration = CFAbsoluteTimeGetCurrent() - start
        return String(format: "Local processing time: %.2fms", duration * 1000)
    }
}

enum AIError: Error {
    case embeddingFailed
    case generationFailed
} 
