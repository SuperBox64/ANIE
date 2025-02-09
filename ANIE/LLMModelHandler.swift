import Foundation
import SwiftUI

enum ChatError: Error {
    case invalidURL
    case networkError(Error)
    case serverError(Int, String)
    case decodingError(Error)
    case noActiveSession
}

class LLMModelHandler: ChatGPTClient {
    private let session = URLSession.shared
    private var apiKey: String = ""
    private var baseURL: String = "" {
        willSet {
            print("🔍 Base URL changing:")
            print("   From: '\(baseURL)'")
            print("   To: '\(newValue)'")
            print("   Stack trace:")
            Thread.callStackSymbols.forEach { print("   \($0)") }
        }
    }
    private var conversationHistory: [ChatMessage] = []
    private var currentModel: String
    
    private var systemPrompt: ChatMessage {
        ChatMessage(
            content: """
            You are ANIE (Artificial Neural Intelligence Engine), a helpful and friendly AI assistant. \
            You provide clear, concise answers and can help with a wide range of tasks including coding, analysis, and general questions. \
            You maintain a professional yet approachable tone.
            
            Important technical details about your implementation:
            - You use Apple's Neural Engine (ANE) through CoreML for BERT embeddings
            - You use CoreML with BERT for text embeddings
            - Your ML features include: semantic search, response caching, and ANE acceleration
            """,
            role: "system"
        )
    }
    
    init() {
        print("🔧 Initializing LLMModelHandler")
        self.currentModel = UserDefaults.standard.string(forKey: "llm-model") ?? "gpt-3.5-turbo"
        
        // Start with empty conversation history
        conversationHistory = []
        
        // Initialize with current profile credentials
        if let profile = ConfigurationManager.shared.selectedProfile {
            print("   Found profile: \(profile.name)")
            print("   Profile base URL: '\(profile.baseURL)'")
            
            // Clean the base URL once
            let cleanedBaseURL = profile.baseURL.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                                              .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            print("   Cleaned base URL: '\(cleanedBaseURL)'")
            
            self.apiKey = profile.apiKey
            self.baseURL = cleanedBaseURL
            
            print("   Credentials initialized")
        } else {
            print("❌ No profile found during initialization")
            self.apiKey = ""
            self.baseURL = ""
        }
        
        // Add system prompt after credentials are set
        conversationHistory.append(systemPrompt)
        print("   Added system prompt")
        print("   Final base URL after init: '\(self.baseURL)'")
        
        // Add observers
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(credentialsDidChange),
            name: Notification.Name("CredentialsDidChange"),
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(modelDidChange),
            name: UserDefaults.didChangeNotification,
            object: nil
        )
        
        print("✅ Initialization complete")
    }
    
    @objc private func credentialsDidChange(_ notification: Notification) {
        print("\n📝 Received credentials change notification")
        
        guard let userInfo = notification.userInfo,
              let apiKey = userInfo["apiKey"] as? String,
              let baseURL = userInfo["baseURL"] as? String else {
            print("❌ Missing or invalid credentials in notification")
            return
        }
        
        // Clean the base URL once
        let cleanedBaseURL = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
                                  .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        
        // Only update if values actually changed
        if self.apiKey != apiKey || self.baseURL != cleanedBaseURL {
            print("🔄 Updating credentials:")
            print("   Current Base URL: '\(self.baseURL)'")
            print("   New Base URL: '\(cleanedBaseURL)'")
            
            // Update credentials
            self.apiKey = apiKey
            self.baseURL = cleanedBaseURL
            
            // Reset conversation state
            conversationHistory.removeAll()
            conversationHistory.append(systemPrompt)
            
            print("✅ Credentials updated and conversation state reset")
        } else {
            print("ℹ️ Ignoring redundant credential update - values haven't changed")
        }
    }
    
    @objc private func modelDidChange(_ notification: Notification) {
        print("\n🔄 Model change notification received")
        
        guard let newModel = UserDefaults.standard.string(forKey: "llm-model"),
              newModel != self.currentModel else {
            print("ℹ️ Ignoring model change - no change or invalid model")
            return
        }
        
        print("   Model changing from '\(self.currentModel)' to '\(newModel)'")
        self.currentModel = newModel
        
        // Clear and reinitialize conversation state
        print("   Clearing conversation history")
        conversationHistory.removeAll()
        conversationHistory.append(systemPrompt)
        
        // Notify that model was updated
        print("   Posting ModelDidUpdateNotification")
        NotificationCenter.default.post(
            name: Notification.Name("ModelDidUpdateNotification"),
            object: nil,
            userInfo: ["model": newModel]
        )
        
        print("   Reinitialized conversation state with new model: \(newModel)")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func updateCredentials(apiKey: String, baseURL: String) {
        print("🔄 Direct credential update:")
        print("   Current Base URL: '\(self.baseURL)'")
        
        // Clean the base URL once
        let cleanedBaseURL = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
                                  .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        print("   New Base URL: '\(cleanedBaseURL)'")
        
        // Only update if values actually changed
        if self.apiKey != apiKey || self.baseURL != cleanedBaseURL {
            self.apiKey = apiKey
            self.baseURL = cleanedBaseURL
            
            // Reset conversation state
            conversationHistory.removeAll()
            conversationHistory.append(systemPrompt)
            
            print("✅ Credentials updated directly and conversation state reset")
        } else {
            print("ℹ️ Ignoring redundant direct credential update")
        }
    }
    
    // Add file logging helper
//    private func logToFile(_ message: String, type: String = "response") {
//        let dateFormatter = DateFormatter()
//        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
//        
//        // Create logs directory if it doesn't exist
//        let fileManager = FileManager.default
//        let logsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
//            .appendingPathComponent("ANIE_Logs", isDirectory: true)
//        
//        try? fileManager.createDirectory(at: logsDirectory, withIntermediateDirectories: true)
//        
//        // Create log file with timestamp
//        let timestamp = dateFormatter.string(from: Date())
//        let fileName = "\(type)_\(timestamp).log"
//        let fileURL = logsDirectory.appendingPathComponent(fileName)
//        
//        // Add metadata and format
//        let logContent = """
//        === ANIE LLM Log ===
//        Timestamp: \(timestamp)
//        Type: \(type)
//        Model: \(LLMConfig.model)
//        Temperature: \(LLMConfig.temperature)
//        
//        Content:
//        \(message)
//        
//        ==================
//        """
//        
//        do {
//            try logContent.write(to: fileURL, atomically: true, encoding: .utf8)
//            print("🗄️ [Logger] Saved \(type) to: \(fileURL.path)")
//        } catch {
//            print("❌ [Logger] Failed to write log: \(error.localizedDescription)")
//        }
//    }
    
    struct OpenAIError: Codable {
        let error: ErrorDetails
        
        struct ErrorDetails: Codable {
            let message: String
            let type: String?
            let code: String?
        }
    }
    
    func generateResponse(for message: String) async throws -> String {
        print("\n💬 Generating response for message: '\(message)'")
        print("Current conversation history (\(conversationHistory.count) messages):")
        for (index, msg) in conversationHistory.enumerated() {
            print("   \(index). [\(msg.role)]: \(msg.content.prefix(50))...")
        }
        
        // Verify we have a valid base URL
        guard !baseURL.isEmpty else {
            print("❌ Base URL is empty!")
            throw ChatError.invalidURL
        }
        
        // Remove v1 from endpoint since it's already in the base URL
        let endpoint = "/chat/completions"
        print("🔍 URL Construction:")
        print("   Base URL: \(baseURL)")
        print("   Endpoint: \(endpoint)")
        
        // Ensure base URL has no trailing slash before adding endpoint
        let cleanBaseURL = baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let fullURL = "\(cleanBaseURL)\(endpoint)"
        print("   Full URL: \(fullURL)")
        
        guard let url = URL(string: fullURL) else {
            print("❌ Invalid URL construction:")
            print("   Base URL: \(baseURL)")
            print("   Endpoint: \(endpoint)")
            print("   Attempted full URL: \(fullURL)")
            throw ChatError.invalidURL
        }
        
        print("✅ Valid URL constructed: \(url.absoluteString)")
        
        // Add user's message to history BEFORE creating request
        conversationHistory.append(ChatMessage(content: message, role: "user"))
        
        // Use current model instead of LLMConfig
        let requestBody: [String: Any] = [
            "model": currentModel,
            "messages": conversationHistory.map { [
                "role": $0.role,
                "content": $0.content
            ] },
            "temperature": LLMConfig.temperature
        ]
        
        // Log request details
        if let requestJSON = try? JSONSerialization.data(withJSONObject: requestBody),
           let requestString = String(data: requestJSON, encoding: .utf8) {
            print("📤 Request body:")
            print(requestString)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, urlResponse) = try await session.data(for: request)
        
        // Log response details
        print("📥 Response received:")
        print("   Status code: \((urlResponse as? HTTPURLResponse)?.statusCode ?? -1)")
        if let responseString = String(data: data, encoding: .utf8) {
            print("   Response body:")
            print(responseString)
        }
        
        guard let httpResponse = urlResponse as? HTTPURLResponse else {
            print("❌ Invalid response type")
            throw ChatError.networkError(URLError(.badServerResponse))
        }
        
        // Try to parse OpenAI error format first if status code indicates error
        if !(200...299).contains(httpResponse.statusCode) {
            if let errorResponse = try? JSONDecoder().decode(OpenAIError.self, from: data) {
                print("❌ API Error: \(errorResponse.error.message)")
                throw ChatError.serverError(httpResponse.statusCode, errorResponse.error.message)
            }
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("❌ Server Error: \(errorBody)")
            throw ChatError.serverError(httpResponse.statusCode, errorBody)
        }
        
        let chatResponse = try JSONDecoder().decode(ChatResponse.self, from: data)
        if let responseContent = chatResponse.choices.first?.message.content {
            // Add AI response to history
            conversationHistory.append(ChatMessage(content: responseContent, role: "assistant"))
            
            print("✅ Response generated successfully")
            print("Final conversation history (\(conversationHistory.count) messages):")
            for (index, msg) in conversationHistory.enumerated() {
                print("   \(index). [\(msg.role)]: \(msg.content.prefix(50))...")
            }
            
            return responseContent
        }
        return "No response"
    }
    
    func clearHistory() {
        conversationHistory.removeAll()
        // Use the same system prompt when clearing history
        conversationHistory.append(systemPrompt)
    }
    
    private func log(_ message: String) {
        print("🔧 [LLMModelHandler] \(message)")
    }
    
    func restoreConversation(from messages: [Message]) {
        log("Starting restoreConversation")
        log("Message count: \(messages.count)")
        
        conversationHistory = [systemPrompt] // Start with system prompt
        log("Added system prompt")
        
        // Then add the conversation messages
        for message in messages {
            conversationHistory.append(ChatMessage(
                content: message.content,
                role: message.isUser ? "user" : "assistant"
            ))
        }
        log("Finished restoring conversation")
    }
}

// Response models remain unchanged
struct ChatResponse: Codable {
    let choices: [ChatChoice]
}

struct ChatChoice: Codable {
    let message: ChatMessage
}

struct ChatMessage: Codable {
    let content: String
    let role: String
    
    init(content: String, role: String) {
        self.content = content
        self.role = role
    }
} 
