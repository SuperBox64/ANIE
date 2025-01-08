import Foundation

enum LLMAIConfig {
    private static let credentialsManager = CredentialsManager()
    
    static var apiKey: String {
        credentialsManager.getCredentials()?.apiKey ?? ""
    }
    
    static var baseURL: String {
        credentialsManager.getCredentials()?.baseURL ?? ""
    }
} 