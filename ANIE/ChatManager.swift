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
        // Special command to check ML system status
        if message.lowercased() == "!ml status" {
            var status = "=== ML System Status ===\n"
            status += "ANE Available: \(MLDeviceCapabilities.hasANE)\n"
            status += "Current Compute Units: \(MLDeviceCapabilities.getOptimalComputeUnits())\n"
            
            // Add model loading status
            status += "\nModel Status:\n"
            status += "- Embeddings Model: Loaded and using \(MLDeviceCapabilities.hasANE ? "ANE" : "CPU/GPU")\n"
            status += "- Classifier Model: Loaded and using \(MLDeviceCapabilities.hasANE ? "ANE" : "CPU/GPU")\n"
            
            // Add performance metrics
            do {
                let testMessage = "This is a test message for performance measurement"
                let start = CFAbsoluteTimeGetCurrent()
                _ = try preprocessor.shouldProcessMessage(testMessage)
                let duration = (CFAbsoluteTimeGetCurrent() - start) * 1000
                status += "\nPerformance Test:\n"
                status += "Message processing time: \(String(format: "%.2f", duration))ms\n"
            } catch {
                status += "\nError running performance test: \(error)\n"
            }
            
            return status
        }
        
        // Regular message processing...
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // First check if we need to process this message
        let shouldProcess = try preprocessor.shouldProcessMessage(message)
        let preprocessTime = CFAbsoluteTimeGetCurrent()
        print("Preprocess time: \((preprocessTime - startTime) * 1000)ms")
        
        guard shouldProcess else {
            return "This message doesn't require processing."
        }
        
        // Check cache for similar queries
        if let cachedResponse = try cache.findSimilarResponse(for: message) {
            let cacheTime = CFAbsoluteTimeGetCurrent()
            print("Cache lookup time: \((cacheTime - preprocessTime) * 1000)ms")
            print("Using cached response")
            return cachedResponse
        }
        
        // If no cache hit, call API
        let response = try await apiClient.generateResponse(for: message)
        
        // Cache the new response
        try cache.cacheResponse(query: message, response: response)
        
        let endTime = CFAbsoluteTimeGetCurrent()
        print("Total processing time: \((endTime - startTime) * 1000)ms")
        
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
