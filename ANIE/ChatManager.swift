import Foundation
//import CoreML

protocol ChatGPTClient {
    func generateResponse(for message: String) async throws -> String
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
        // Add command to check BERT status
        if message.lowercased() == "!bert status" {
            return EmbeddingsService.shared.getStats()
        }
        
        // First check if we need to process this message
        let shouldProcess = try preprocessor.shouldProcessMessage(message)
        
        // Check cache for similar queries using embeddings
        if let cachedResponse = try cache.findSimilarResponse(for: message) {
            print("🤖 Using BERT cache for response")
            return cachedResponse + "\n[Retrieved using BERT]"
        }
        
        print("💭 No cache hit, using ChatGPT")
        // If no cache hit, call ChatGPT API
        let response = try await apiClient.generateResponse(for: message)
        
        // Cache the new response
        try cache.cacheResponse(query: message, response: response)
        
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
