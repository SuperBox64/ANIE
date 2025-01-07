import Foundation

enum ChatError: Error {
    case invalidURL
    case networkError(Error)
    case serverError(Int, String)
    case decodingError(Error)
}

class LLMModelHandler {
    private let session = URLSession.shared
    private var apiKey: String
    private var baseURL: String
    private var conversationHistory: [ChatMessage] = []
    
    init() {
        self.apiKey = OpenAIConfig.apiKey
        self.baseURL = OpenAIConfig.baseURL
        
        // Add system prompt to set AI personality
        let systemPrompt = ChatMessage(
            content: "You are ANIE (Artificial Neural Intelligence Engine), a helpful and friendly AI assistant. You provide clear, concise answers and can help with a wide range of tasks including coding, analysis, and general questions. You maintain a professional yet approachable tone.",
            role: "system"
        )
        conversationHistory.append(systemPrompt)
    }
    
    func updateCredentials(apiKey: String, baseURL: String) {
        self.apiKey = apiKey
        self.baseURL = baseURL
    }
    
    func generateResponse(for input: String) async throws -> String {
        let url = URL(string: "\(baseURL)/chat/completions")!
        
        // Add user's message to history
        conversationHistory.append(ChatMessage(content: input, role: "user"))
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Convert conversation history to dictionary array
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
        
        do {
            let (data, urlResponse) = try await session.data(for: request)
            
            guard let httpResponse = urlResponse as? HTTPURLResponse else {
                throw ChatError.networkError(URLError(.badServerResponse))
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                throw ChatError.serverError(httpResponse.statusCode, String(data: data, encoding: .utf8) ?? "Unknown error")
            }
            
            do {
                let chatResponse = try JSONDecoder().decode(ChatResponse.self, from: data)
                if let responseContent = chatResponse.choices.first?.message.content {
                    // Add AI's response to history
                    conversationHistory.append(ChatMessage(content: responseContent, role: "assistant"))
                    return responseContent
                }
                return "No response"
            } catch {
                throw ChatError.decodingError(error)
            }
        } catch {
            if let chatError = error as? ChatError {
                throw chatError
            }
            throw ChatError.networkError(error)
        }
    }
    
    func clearHistory() {
        conversationHistory.removeAll()
    }
    
    func restoreConversation(from messages: [Message]) {
        conversationHistory = messages.map { message in
            ChatMessage(
                content: message.content,
                role: message.isUser ? "user" : "assistant"
            )
        }
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