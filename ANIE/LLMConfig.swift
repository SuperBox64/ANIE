import Foundation

enum LLMConfig {
    private static let credentialsManager = CredentialsManager()
    
    static var apiKey: String {
        credentialsManager.getCredentials()?.apiKey ?? ""
    }
    
    static var baseURL: String {
        credentialsManager.getCredentials()?.baseURL ?? ""
    }
    
    // Add model configuration
    static var model: String {
        UserDefaults.standard.string(forKey: "llm-model") ?? "gpt-3.5-turbo"
    }
    
    static func setModel(_ model: String) {
        UserDefaults.standard.set(model, forKey: "llm-model")
    }
    
    // Add temperature configuration
    static var temperature: Double {
        let temp = UserDefaults.standard.double(forKey: "llm-temperature")
        return temp > 0 ? temp : 0.7  // Return default if 0 or negative
    }
    
    static func setTemperature(_ temp: Double) {
        UserDefaults.standard.set(temp, forKey: "llm-temperature")
    }
} 