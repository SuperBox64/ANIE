import Foundation
import AppKit
//import CoreML

@MainActor
class LLMViewModel: ObservableObject {
    @Published var sessions: [ChatSession] = []
    @Published var selectedSessionId: UUID?
    @Published var isProcessing = false
    @Published var processingProgress: Double = 0
    @Published var isLoadingSession = false
    @Published var loadedSessions = Set<UUID>()
    @Published var searchTerm: String = ""
    
    private let modelHandler = LLMModelHandler()
    private let sessionsKey = "chatSessions"
    private let selectedSessionKey = "selectedSession"
    private let loadedSessionsKey = "loadedSessions"
    private let credentialsManager = CredentialsManager()
    private var chatManager: ChatManager
    
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
        self.chatManager = ChatManager(
            preprocessor: preprocessor,
            apiClient: modelHandler
        )
        
        loadSessions()
    }
    
    // Add logging helper
    private func log(_ message: String) {
        print("📱 [LLMViewModel] \(message)")
    }
    
    private func loadSessions() {
        log("Starting loadSessions()")
        
        // Load sessions
        if let data = UserDefaults.standard.data(forKey: sessionsKey),
           let savedSessions = try? JSONDecoder().decode([ChatSession].self, from: data) {
            log("Successfully decoded \(savedSessions.count) sessions")
            sessions = savedSessions
            
            // Restore selected session
            if let selectedId = UserDefaults.standard.string(forKey: selectedSessionKey),
               let selectedUUID = UUID(uuidString: selectedId) {
                log("Restoring selected session: \(selectedId)")
                selectedSessionId = selectedUUID
                chatManager.setCurrentSession(selectedUUID)  // Set current session in ChatManager
            } else if let firstSession = sessions.first {
                log("No saved selection, defaulting to first session: \(firstSession.id)")
                selectedSessionId = firstSession.id
                chatManager.setCurrentSession(firstSession.id)  // Set current session in ChatManager
            }
            
            // Restore loaded sessions
            if let loadedData = UserDefaults.standard.array(forKey: loadedSessionsKey) as? [String] {
                loadedSessions = Set(loadedData.compactMap { UUID(uuidString: $0) })
                log("Restored loaded sessions: \(loadedSessions.count)")
            }
            
            // Load the selected session's data
            if let selectedId = selectedSessionId {
                Task {
                    log("Loading selected session data")
                    await loadSessionData(selectedId, forceLoad: true)
                }
            }
        } else {
            log("No sessions data found in UserDefaults")
        }
    }
    
    private func loadSessionData(_ sessionId: UUID, forceLoad: Bool = false) async {
        log("Starting loadSessionData for session: \(sessionId)")
        
        if !forceLoad && loadedSessions.contains(sessionId) {
            log("Session \(sessionId) already loaded, skipping")
            return
        }
        
        await MainActor.run {
            log("Setting isLoadingSession = true")
            isLoadingSession = true
        }
        
        if let session = sessions.first(where: { $0.id == sessionId }) {
            log("Found session to load: \(session.subject)")
            log("Message count: \(session.messages.count)")
            
            await MainActor.run {
                log("Restoring conversation for session: \(sessionId)")
                modelHandler.restoreConversation(from: session.messages)
                log("Adding session to loadedSessions")
                loadedSessions.insert(sessionId)
                log("Setting isLoadingSession = false")
                isLoadingSession = false
            }
        } else {
            log("❌ Session not found: \(sessionId)")
            await MainActor.run {
                isLoadingSession = false
            }
        }
    }
    
    private func saveSessions() {
        // Save sessions
        if let data = try? JSONEncoder().encode(sessions) {
            UserDefaults.standard.set(data, forKey: sessionsKey)
        }
        
        // Save selected session
        if let selectedId = selectedSessionId {
            UserDefaults.standard.set(selectedId.uuidString, forKey: selectedSessionKey)
        }
        
        // Save loaded sessions
        let loadedSessionsArray = loadedSessions.map { $0.uuidString }
        UserDefaults.standard.set(loadedSessionsArray, forKey: loadedSessionsKey)
    }
    
    func addSession(subject: String) {
        let newSession = ChatSession(subject: subject)
        sessions.append(newSession)
        selectedSessionId = newSession.id
        chatManager.setCurrentSession(newSession.id)
        loadedSessions.insert(newSession.id)  // Mark as loaded since it's new
        modelHandler.clearHistory()
        saveSessions()
    }
    
    func removeSession(id: UUID) {
        sessions.removeAll { $0.id == id }
        loadedSessions.remove(id)  // Remove from loaded sessions
        
        if let firstSession = sessions.first {
            selectedSessionId = firstSession.id
            Task {
                await loadSessionData(firstSession.id)
            }
        } else {
            selectedSessionId = nil
            modelHandler.clearHistory()
        }
        saveSessions()
    }
    
    private var lastRestoredSession: UUID?
    
    func selectSession(id: UUID) {
        selectedSessionId = id
        chatManager.setCurrentSession(id)
        
        // Only show loading if we're not already processing a message
        if !isProcessing {
            isLoadingSession = true
            
            Task { @MainActor in
                // Brief loading time for visual feedback
                try? await Task.sleep(nanoseconds: 100_000_000)  // 0.1 seconds
                
                // Restore conversation history for the selected session
                if let session = sessions.first(where: { $0.id == id }) {
                    modelHandler.restoreConversation(from: session.messages)
                }
                
                // Only stop loading and show checkmark if we're not processing a message
                if !isProcessing {
                    isLoadingSession = false
                    loadedSessions.insert(id)
                }
            }
        }
    }
    
    private func addMessage(_ message: Message) {
        guard let index = sessions.firstIndex(where: { $0.id == selectedSessionId }) else { return }
        sessions[index].messages.append(message)
        saveSessions()
    }
    
    @MainActor
    func processUserInput(_ input: String) async {
        guard currentSession != nil else { return }
        
        isProcessing = true
        isLoadingSession = true
        processingProgress = 0.0
        
        // Start progress animation
        Task {
            // Quickly animate to 20% during initial processing
            for i in 1...20 {
                if !isProcessing { break }
                try? await Task.sleep(nanoseconds: 2_000_000) // 0.002s
                processingProgress = Double(i) / 100.0
            }
        }
        
        // Check if the input is an image path
        if input.starts(with: "![") && input.contains("](") {
            let imageData = extractImageData(from: input)
            let message = Message(content: input, isUser: true, imageData: imageData)
            addMessage(message)
            
            processingProgress = 1.0
            isProcessing = false
            isLoadingSession = false
            if let id = selectedSessionId {
                loadedSessions.insert(id)
            }
            return
        }
        
        let message = Message(content: input, isUser: true)
        addMessage(message)
        
        // Progress to 40% after user message is added
        processingProgress = 0.4
        
        do {
            // Start progress animation for API/BERT processing
            let progressTask = Task {
                // Animate from 40% to 90% during processing
                for i in 40...90 {
                    if !isProcessing { break }
                    try? await Task.sleep(nanoseconds: 10_000_000) // 0.01s per percent
                    processingProgress = Double(i) / 100.0
                }
            }
            
            let response = try await chatManager.processMessage(input)
            
            // Cancel the progress animation task
            progressTask.cancel()
            
            // Progress to 95% after getting response
            processingProgress = 0.95
            
            let usedBERT = response.contains("[Retrieved using BERT]")
            let usedLocalAI = response.contains("[Using LocalAI]")
            let cleanResponse = response
                .replacingOccurrences(of: "\n[Retrieved using BERT]", with: "")
                .replacingOccurrences(of: "\n[Using LocalAI]", with: "")
            
            let responseMessage = Message(
                content: cleanResponse,
                isUser: false,
                usedBERT: usedBERT,
                usedLocalAI: usedLocalAI
            )
            
            // Progress to 100% right before adding message
            processingProgress = 1.0
            
            addMessage(responseMessage)
            
            // Complete immediately
            isProcessing = false
            isLoadingSession = false
            if let id = selectedSessionId {
                loadedSessions.insert(id)
            }
            
        } catch {
            print("Error processing message: \(error)")
            
            let errorMessage: String
            switch error {
            case let ChatError.serverError(code, message):
                errorMessage = "Error (\(code)): \(message)"
            case let ChatError.networkError(underlying):
                errorMessage = "Network Error: \(underlying.localizedDescription)"
            case ChatError.invalidURL:
                errorMessage = "Error: Invalid API URL"
            case let ChatError.decodingError(underlying):
                errorMessage = "Error: Failed to process response - \(underlying.localizedDescription)"
            default:
                errorMessage = "Error: \(error.localizedDescription)"
            }
            
            let responseMessage = Message(
                content: errorMessage,
                isUser: false,
                isError: true
            )
            
            // Set to 100% before showing error
            processingProgress = 1.0
            addMessage(responseMessage)
            
            // Complete immediately
            isProcessing = false
            isLoadingSession = false
            if let id = selectedSessionId {
                loadedSessions.insert(id)
            }
        }
    }
    
    private func extractImageData(from input: String) -> Data? {
        // Extract image path from markdown format: ![Alt text](path)
        let pattern = #"\!\[.*\]\((.*)\)"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: input, range: NSRange(input.startIndex..., in: input)),
              let pathRange = Range(match.range(at: 1), in: input) else {
            return nil
        }
        
        let imagePath = String(input[pathRange])
        
        // Try to load the image from the path
        if let image = NSImage(contentsOfFile: imagePath) {
            return image.tiffRepresentation
        }
        
        return nil
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
            
            // Reinitialize chat manager with updated model handler
            let preprocessor = MessagePreprocessor()
            self.chatManager = ChatManager(
                preprocessor: preprocessor,
                apiClient: modelHandler
            )
            
            // Restore conversation state if there's an active session
            if let session = currentSession {
                modelHandler.restoreConversation(from: session.messages)
            }
        }
    }
    
    func removeLastMessage(_ sessionId: UUID) {
        if var session = sessions.first(where: { $0.id == sessionId }) {
            // Remove last two messages (Q&A pair) if they exist
            if session.messages.count >= 2 {
                session.messages.removeLast(2)
            } else if session.messages.count == 1 {
                session.messages.removeLast()
            }
            
            // Update session
            if let index = sessions.firstIndex(where: { $0.id == sessionId }) {
                sessions[index] = session
                
                // Update model handler with new history
                modelHandler.restoreConversation(from: session.messages)
                
                saveSessions()
            }
        }
    }
    
    var filteredMessages: [Message]? {
        guard let session = currentSession, !searchTerm.isEmpty else { return nil }
        return session.messages.filter { message in
            message.content.localizedCaseInsensitiveContains(searchTerm)
        }
    }
} 
