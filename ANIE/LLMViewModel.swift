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
    
    private let modelHandler = LLMModelHandler()
    private let sessionsKey = "chatSessions"
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
        // Create default session if none exist
        if sessions.isEmpty {
            addSession(subject: "New Chat")
        }
    }
    
    // Add logging helper
    private func log(_ message: String) {
        print("📱 [LLMViewModel] \(message)")
    }
    
    private func loadSessions() {
        log("Starting loadSessions()")
        if let data = UserDefaults.standard.data(forKey: sessionsKey) {
            log("Found data in UserDefaults")
            if let savedSessions = try? JSONDecoder().decode([ChatSession].self, from: data) {
                log("Successfully decoded \(savedSessions.count) sessions")
                sessions = savedSessions
                
                if let firstSession = sessions.first {
                    log("Loading first session: \(firstSession.id)")
                    selectedSessionId = firstSession.id
                    Task {
                        log("Starting initial session load task")
                        await loadSessionData(firstSession.id)
                    }
                } else {
                    log("No sessions available after loading")
                }
            } else {
                log("❌ Failed to decode sessions data")
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
        if let data = try? JSONEncoder().encode(sessions) {
            UserDefaults.standard.set(data, forKey: sessionsKey)
        }
    }
    
    func addSession(subject: String) {
        let newSession = ChatSession(subject: subject)
        sessions.append(newSession)
        selectedSessionId = newSession.id
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
        log("selectSession called with id: \(id)")
        log("Current selectedSessionId: \(String(describing: selectedSessionId))")
        
        guard selectedSessionId != id else {
            log("Session already selected, skipping")
            return
        }
        
        log("Updating selectedSessionId to: \(id)")
        selectedSessionId = id
        
        // Force load even if already loaded
        Task {
            log("Starting loadSessionData task")
            await loadSessionData(id, forceLoad: true)
            log("Triggering scroll to bottom")
            ScrollManager.shared.scrollToBottom()
        }
    }
    
    private func addMessage(_ message: Message) {
        guard let index = sessions.firstIndex(where: { $0.id == selectedSessionId }) else { return }
        sessions[index].messages.append(message)
        saveSessions()
        ScrollManager.shared.scrollToBottom()
    }
    
    @MainActor
    func processUserInput(_ input: String) async {
        guard currentSession != nil else { return }
        
        isProcessing = true
        processingProgress = 0.0
        
        // Check if the input is an image path
        if input.starts(with: "![") && input.contains("](") {
            let imageData = extractImageData(from: input)
            let message = Message(content: input, isUser: true, imageData: imageData)
            addMessage(message)
            
            isProcessing = false
            processingProgress = 1.0
            return
        }
        
        let message = Message(content: input, isUser: true)
        addMessage(message)
        
        do {
            let response = try await chatManager.processMessage(input)
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
            
            addMessage(responseMessage)
            isProcessing = false
            processingProgress = 1.0
        } catch {
            print("Error processing message: \(error)")
            isProcessing = false
            processingProgress = 1.0
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
} 
