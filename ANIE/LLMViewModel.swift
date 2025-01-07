import Foundation
import CoreML
import SwiftUI

// MARK: - View Model
@MainActor
class LLMViewModel: ObservableObject {
    @Published var sessions: [ChatSession] = []
    @Published var selectedSessionId: UUID?
    @Published var isProcessing = false
    @Published var processingProgress: Double = 0
    
    private let modelHandler = LLMModelHandler()
    private let sessionsKey = "chatSessions"
    private let credentialsManager = CredentialsManager()
    private var chatManager: ChatManager?
    
    var currentSession: ChatSession? {
        get {
            guard let id = selectedSessionId else { return nil }
            return sessions.first { $0.id == id }
        }
        set {
            if let newSession = newValue {
                if let index = sessions.firstIndex(where: { $0.id == newSession.id }) {
                    sessions[index] = newSession
                    saveSessions()
                }
            }
        }
    }
    
    var hasValidCredentials: Bool {
        if let credentials = credentialsManager.getCredentials() {
            return !credentials.apiKey.isEmpty
        }
        return false
    }
    
    init() {
        loadSessions()
        // Create default session if none exist
        if sessions.isEmpty {
            addSession(subject: "New Chat")
        }
        
        // Initialize ML components
        do {
            let preprocessor = try CustomMessagePreprocessor()
            let embeddingsGenerator = try EmbeddingsGenerator()
            let cache = ResponseCache(embeddingsGenerator: embeddingsGenerator)
            chatManager = ChatManager(
                preprocessor: preprocessor,
                cache: cache,
                apiClient: modelHandler
            )
        } catch {
            print("Failed to initialize ML components: \(error)")
        }
    }
    
    private func loadSessions() {
        if let data = UserDefaults.standard.data(forKey: sessionsKey),
           let savedSessions = try? JSONDecoder().decode([ChatSession].self, from: data) {
            sessions = savedSessions
            selectedSessionId = sessions.first?.id
            if let session = currentSession {
                modelHandler.restoreConversation(from: session.messages)
            }
        }
    }
    
    private func saveSessions() {
        if let data = try? JSONEncoder().encode(sessions) {
            UserDefaults.standard.set(data, forKey: sessionsKey)
        }
    }
    
    func addSession(subject: String) {
        let newSession = ChatSession(subject: subject)
        sessions.append(newSession)
        selectedSessionId = newSession.id
        modelHandler.clearHistory()
        saveSessions()
    }
    
    func removeSession(id: UUID) {
        sessions.removeAll { $0.id == id }
        selectedSessionId = sessions.first?.id
        if let session = currentSession {
            modelHandler.restoreConversation(from: session.messages)
        } else {
            modelHandler.clearHistory()
        }
        saveSessions()
    }
    
    func selectSession(id: UUID) {
        selectedSessionId = id
        if let session = currentSession {
            modelHandler.restoreConversation(from: session.messages)
        }
    }
    
    func processUserInput(_ input: String) async {
        guard var session = currentSession else { return }
        isProcessing = true
        processingProgress = 0
        
        let userMessage = Message(content: input, isUser: true)
        session.messages.append(userMessage)
        currentSession = session
        
        // Simulate progress while waiting for response
        Task {
            while isProcessing {
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
                if processingProgress < 0.95 {  // Cap at 95% until actual completion
                    processingProgress += 0.05
                }
            }
        }
        
        do {
            let response: String
            if let manager = chatManager {
                response = try await manager.processMessage(input)
            } else {
                response = try await modelHandler.generateResponse(for: input)
            }
            
            session.messages.append(Message(content: response, isUser: false))
            currentSession = session
        } catch ChatError.serverError(let code, let message) {
            session.messages.append(Message(content: "Server error (\(code)): \(message)", isUser: false))
            currentSession = session
        } catch ChatError.networkError(let error) {
            session.messages.append(Message(content: "Network error: \(error.localizedDescription)", isUser: false))
            currentSession = session
        } catch {
            session.messages.append(Message(content: "Error: \(error.localizedDescription)", isUser: false))
            currentSession = session
        }
        
        processingProgress = 1.0  // Complete the progress
        isProcessing = false
    }
    
    func clearSessionHistory(_ sessionId: UUID) {
        if var session = sessions.first(where: { $0.id == sessionId }) {
            session.messages.removeAll()
            currentSession = session
            modelHandler.clearHistory()
            saveSessions()
        }
    }
    
    func refreshCredentials() {
        if let credentials = credentialsManager.getCredentials() {
            modelHandler.updateCredentials(apiKey: credentials.apiKey, baseURL: credentials.baseURL)
        }
    }
} 
