import Foundation

enum ChatError: Error {
    case invalidURL
    case networkError(Error)
    case serverError(Int, String)
    case decodingError(Error)
    case noActiveSession
}

class LLMModelHandler: ChatGPTClient {
    private let session = URLSession.shared
    private var apiKey: String
    private var baseURL: String
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
        self.apiKey = LLMAIConfig.apiKey
        self.baseURL = LLMAIConfig.baseURL
        self.currentModel = UserDefaults.standard.string(forKey: "llm-model") ?? "gpt-3.5-turbo"
        conversationHistory.append(systemPrompt)
        
        // Add observer for credential changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(credentialsDidChange),
            name: Notification.Name("CredentialsDidChange"),
            object: nil
        )
        
        // Add observer for model changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(modelDidChange),
            name: UserDefaults.didChangeNotification,
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
    
    @objc private func modelDidChange(_ notification: Notification) {
        if let newModel = UserDefaults.standard.string(forKey: "llm-model") {
            self.currentModel = newModel
            print("🔄 Model updated to: \(newModel)")
            
            // Clear and reinitialize conversation state
            conversationHistory.removeAll()
            conversationHistory.append(systemPrompt)
            
            // Notify that model was updated
            NotificationCenter.default.post(
                name: Notification.Name("ModelDidUpdateNotification"),
                object: nil,
                userInfo: ["model": newModel]
            )
            
            print("🔄 Reinitialized conversation state with new model: \(newModel)")
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func updateCredentials(apiKey: String, baseURL: String) {
        self.apiKey = apiKey
        self.baseURL = baseURL
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
    
    private var isReasoningModel: Bool {
        currentModel.hasPrefix("o1") || currentModel.hasPrefix("o3")
    }
    
    func generateResponse(for message: String) async throws -> String {
        // Different endpoints for GPT vs reasoning models
        let endpoint = isReasoningModel ? "/v1/completions" : "/v1/chat/completions"
        let url = URL(string: "\(baseURL)\(endpoint)")!
        
        var requestBody: [String: Any]
        
        if isReasoningModel {
            // Reasoning models use different request format
            requestBody = [
                "model": currentModel,
                "prompt": message,
                "temperature": LLMConfig.temperature,
                "max_tokens": 2048,
                "stream": false,
                "stop": ["\n\n"]  // Add stop sequence for reasoning models
            ]
        } else {
            // GPT models use chat format
            requestBody = [
                "model": currentModel,
                "messages": conversationHistory.map { [
                    "role": $0.role,
                    "content": $0.content
                ] },
                "temperature": LLMConfig.temperature
            ]
        }
        
        // Only maintain conversation history for GPT models
        if !isReasoningModel {
            conversationHistory.append(ChatMessage(content: message, role: "user"))
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        print("🔄 Sending request to: \(url.absoluteString)")
        print("📝 Request body: \(String(data: request.httpBody ?? Data(), encoding: .utf8) ?? "")")
        
        let (data, urlResponse) = try await session.data(for: request)
        
        guard let httpResponse = urlResponse as? HTTPURLResponse else {
            throw ChatError.networkError(URLError(.badServerResponse))
        }
        
        // Log response for debugging
        print("📥 Response status: \(httpResponse.statusCode)")
        print("📥 Response data: \(String(data: data, encoding: .utf8) ?? "")")
        
        // Handle errors
        if !(200...299).contains(httpResponse.statusCode) {
            if let errorResponse = try? JSONDecoder().decode(OpenAIError.self, from: data) {
                throw ChatError.serverError(httpResponse.statusCode, errorResponse.error.message)
            }
            throw ChatError.serverError(httpResponse.statusCode, String(data: data, encoding: .utf8) ?? "Unknown error")
        }
        
        // Parse response based on model type
        if isReasoningModel {
            do {
                let reasoningResponse = try JSONDecoder().decode(ReasoningResponse.self, from: data)
                return reasoningResponse.text
            } catch {
                print("❌ Failed to decode reasoning response: \(error)")
                // Try alternate response format
                if let jsonResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let choices = jsonResponse["choices"] as? [[String: Any]],
                   let firstChoice = choices.first,
                   let text = firstChoice["text"] as? String {
                    return text
                }
                throw ChatError.decodingError(error)
            }
        } else {
            let chatResponse = try JSONDecoder().decode(ChatResponse.self, from: data)
            if let responseContent = chatResponse.choices.first?.message.content {
                conversationHistory.append(ChatMessage(content: responseContent, role: "assistant"))
                return responseContent
            }
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

// Update ReasoningResponse to handle both formats
struct ReasoningResponse: Codable {
    let text: String
    let choices: [ReasoningChoice]?
    
    enum CodingKeys: String, CodingKey {
        case text
        case choices
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let choices = try? container.decode([ReasoningChoice].self, forKey: .choices),
           let firstChoice = choices.first {
            self.choices = choices
            self.text = firstChoice.text
        } else {
            self.text = try container.decode(String.self, forKey: .text)
            self.choices = nil
        }
    }
}

struct ReasoningChoice: Codable {
    let text: String
} 
