import Foundation

class CredentialsManager: ObservableObject {
    @Published var isConfigured: Bool {
        didSet {
            UserDefaults.standard.set(isConfigured, forKey: "isConfigured")
        }
    }
    
    private let configManager = ConfigurationManager.shared
    
    init() {
        self.isConfigured = UserDefaults.standard.bool(forKey: "isConfigured")
    }
    
    func getCredentials() -> (apiKey: String, baseURL: String)? {
        guard let profile = configManager.selectedProfile else {
            return nil
        }
        
        // Just return the profile data directly
        return (profile.apiKey, profile.baseURL)
    }
    
    func clearCredentials() {
        isConfigured = false
    }
} 