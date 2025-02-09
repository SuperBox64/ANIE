import Foundation

protocol ChatGPTClient {
    func generateResponse(for message: String) async throws -> String
    func clearHistory()
} 
