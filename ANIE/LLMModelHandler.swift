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
        self.apiKey = OpenAIConfig.apiKey
        self.baseURL = OpenAIConfig.baseURL
        conversationHistory.append(systemPrompt)
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
            "model": "gpt-3.5-turbo",
            "messages": messages,
            "temperature": 0.7
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
    
    func restoreConversation(from messages: [Message]) {
        conversationHistory = [systemPrompt] // Start with system prompt
        // Then add the conversation messages
        conversationHistory.append(contentsOf: messages.map { message in
            ChatMessage(
                content: message.content,
                role: message.isUser ? "user" : "assistant"
            )
        })
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
