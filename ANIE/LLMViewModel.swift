import Foundation
//import CoreML

@MainActor
class LLMViewModel: ObservableObject {
    @Published var sessions: [ChatSession] = []
    @Published var selectedSessionId: UUID?
    @Published var isProcessing = false
    @Published var processingProgress: Double = 0
    
    private let modelHandler = LLMModelHandler()
    private let sessionsKey = "chatSessions"
    private let credentialsManager = CredentialsManager()
    private let chatManager: ChatManager
    
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
        // Initialize dependencies
        let preprocessor = MessagePreprocessor()
        let cache = ResponseCache()
        self.chatManager = ChatManager(
            preprocessor: preprocessor,
            cache: cache,
            apiClient: modelHandler
        )
        
        loadSessions()
        // Create default session if none exist
        if sessions.isEmpty {
            addSession(subject: "New Chat")
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
        await MainActor.run {
            if let index = sessions.firstIndex(where: { $0.id == selectedSessionId }) {
                sessions[index].messages.append(userMessage)
            }
        }
        
        do {
            let response = try await chatManager.processMessage(input)
            let usedBERT = response.contains("[Retrieved using BERT]")
            let cleanResponse = response.replacingOccurrences(of: "\n[Retrieved using BERT]", with: "")
            
            let responseMessage = Message(
                content: cleanResponse,
                isUser: false,
                usedBERT: usedBERT
            )
            
            await MainActor.run {
                if let index = sessions.firstIndex(where: { $0.id == selectedSessionId }) {
                    sessions[index].messages.append(responseMessage)
                    saveSessions()
                }
            }
        } catch {
            let errorMessage = Message(
                content: "Error: \(error.localizedDescription)",
                isUser: false,
                usedBERT: false
            )
            await MainActor.run {
                if let index = sessions.firstIndex(where: { $0.id == selectedSessionId }) {
                    sessions[index].messages.append(errorMessage)
                    saveSessions()
                }
            }
        }
        
        await MainActor.run {
            isProcessing = false
            processingProgress = 1.0
        }
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
