import Foundation
import CoreML
import SwiftUI

// MARK: - ML Device Capabilities
public struct MLDeviceCapabilities {
    public static var hasANE: Bool {
        if #available(iOS 14.0, macOS 11.0, *) {
            let supportedUnits = MLComputeUnits.all
            return supportedUnits.rawValue & MLComputeUnits.cpuAndNeuralEngine.rawValue != 0
        }
        return false
    }
    
    public static func getOptimalComputeUnits() -> MLComputeUnits {
        if hasANE {
            return .all
        }
        return .cpuAndGPU
    }
    
    public static func debugComputeInfo() {
        print("ANE Available: \(hasANE)")
        print("Optimal Compute Units: \(getOptimalComputeUnits())")
        
        if #available(iOS 14.0, macOS 11.0, *) {
            print("Supported Units: \(MLComputeUnits.all)")
        }
    }
    
    public static func runModelTests() -> String {
        var result = "=== ML System Test Results ===\n"
        result += "ANE Available: \(hasANE)\n"
        result += "Current Compute Units: \(getOptimalComputeUnits())\n"
        return result
    }
}

// MARK: - Chat Manager
public class ChatManager {
    private let preprocessor: CustomMessagePreprocessor
    private let cache: ResponseCache
    private let apiClient: ChatGPTClient
    
    public init(preprocessor: CustomMessagePreprocessor, cache: ResponseCache, apiClient: ChatGPTClient) {
        self.preprocessor = preprocessor
        self.cache = cache
        self.apiClient = apiClient
        
        // Print debug info on initialization
        print("=== ML System Configuration ===")
        MLDeviceCapabilities.debugComputeInfo()
        print("============================")
    }
    
    public func processMessage(_ message: String) async throws -> String {
        // Handle test commands
        if message.hasPrefix("!") {
            return try await handleCommand(message)
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
    
    private func handleCommand(_ command: String) async throws -> String {
        // Split command into parts and get the base command
        let parts = command.lowercased().split(separator: " ")
        guard parts.count >= 1 else { return "Invalid command" }
        
        let baseCommand = String(parts[0])
        let subCommand = parts.count > 1 ? String(parts[1]) : ""
        
        switch baseCommand {
        case "!ml":
            switch subCommand {
            case "status":
                return MLDeviceCapabilities.runModelTests()
                
            case "test":
                var result = "=== Running ML Tests ===\n\n"
                
                // Test message preprocessing
                result += "Testing Message Preprocessor:\n"
                let testMessages = [
                    "Hello, how are you?",
                    "What's the weather like today?",
                    "Can you help me with a complex programming task?"
                ]
                
                for message in testMessages {
                    let shouldProcess = try preprocessor.shouldProcessMessage(message)
                    result += "- Message: \"\(message)\"\n"
                    result += "  Should process: \(shouldProcess)\n"
                }
                
                // Test response cache
                result += "\nTesting Response Cache:\n"
                let testQuery = "This is a test query"
                let testResponse = "This is a test response"
                
                // Test caching
                try cache.cacheResponse(query: testQuery, response: testResponse)
                result += "- Cache storage: Passed\n"
                
                // Test retrieval
                if let cached = try cache.findSimilarResponse(for: testQuery) {
                    result += "- Cache retrieval: Passed\n"
                    result += "- Retrieved response matches: \(cached == testResponse)\n"
                } else {
                    result += "- Cache retrieval: Failed\n"
                }
                
                // Test similar query
                let similarQuery = "This is a test question"
                if let similar = try cache.findSimilarResponse(for: similarQuery) {
                    result += "- Similar query test: Passed\n"
                    result += "- Similar query response: \"\(similar)\"\n"
                }
                
                result += "\n=== Test Complete ===\n"
                return result
                
            case "help", "":
                return """
                Available Commands:
                !ml status - Show ML system status
                !ml test - Run ML component tests
                !help - Show this help message
                """
                
            default:
                return "Unknown ML command. Type !ml help for available commands."
            }
            
        case "!help":
            return """
            Available Commands:
            !ml status - Show ML system status
            !ml test - Run ML component tests
            !help - Show this help message
            """
            
        default:
            return "Unknown command. Type !help for available commands."
        }
    }
} 