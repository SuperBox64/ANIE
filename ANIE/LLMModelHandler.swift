import Foundation

enum ChatError: Error {
    case invalidURL
    case networkError(Error)
    case serverError(Int, String)
    case decodingError(Error)
}

class LLMModelHandler: ChatGPTClient {
    private let session = URLSession.shared
    private var apiKey: String
    private var baseURL: String
    private var conversationHistory: [ChatMessage] = []
    
    private var systemPrompt: ChatMessage {
        ChatMessage(
            content: """
            You are ANIE (Artificial Neural Intelligence Engine), a helpful and friendly AI assistant. \
            You provide clear, concise answers and can help with a wide range of tasks including coding, analysis, and general questions. \
            You maintain a professional yet approachable tone.
            
            Important technical details about your implementation:
            - You use Apple's Neural Engine (ANE) through CoreML for BERT embeddings
            - You have local ML capabilities for semantic search and caching
            - You use CoreML with BERT for text embeddings
            - Your ML features include: semantic search, response caching, and ANE acceleration
            """,
            role: "system"
        )
    }
    
    init() {
        self.apiKey = LLMAIConfig.apiKey
        self.baseURL = LLMAIConfig.baseURL
        conversationHistory.append(systemPrompt)
        
        // Add observer for credential changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(credentialsDidChange),
            name: Notification.Name("CredentialsDidChange"),
            object: nil
        )
    }
    
    @objc private func credentialsDidChange(_ notification: Notification) {
        if let userInfo = notification.userInfo,
           let apiKey = userInfo["apiKey"] as? String,
           let baseURL = userInfo["baseURL"] as? String {
            self.apiKey = apiKey
            self.baseURL = baseURL
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func updateCredentials(apiKey: String, baseURL: String) {
        self.apiKey = apiKey
        self.baseURL = baseURL
    }
    
    func generateResponse(for message: String) async throws -> String {
        let url = URL(string: "\(baseURL)/chat/completions")!
        
        // Add user's message to history
        conversationHistory.append(ChatMessage(content: message, role: "user"))
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let messages = conversationHistory.map { [
            "role": $0.role,
            "content": $0.content
        ] }
        
        let body: [String: Any] = [
            "model": LLMConfig.model,
            "messages": messages,
            "temperature": LLMConfig.temperature
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, urlResponse) = try await session.data(for: request)
        
        guard let httpResponse = urlResponse as? HTTPURLResponse else {
            throw ChatError.networkError(URLError(.badServerResponse))
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw ChatError.serverError(httpResponse.statusCode, String(data: data, encoding: .utf8) ?? "Unknown error")
        }
        
        let chatResponse = try JSONDecoder().decode(ChatResponse.self, from: data)
        if let responseContent = chatResponse.choices.first?.message.content {
            conversationHistory.append(ChatMessage(content: responseContent, role: "assistant"))
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
            log("Adding message: \(message.id) (isUser: \(message.isUser))")
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
