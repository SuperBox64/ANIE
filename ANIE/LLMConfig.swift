import Foundation
import SwiftUI

enum LLMConfig {
    private static let configManager = ConfigurationManager.shared
    
    static var apiKey: String {
        configManager.selectedProfile?.apiKey ?? ""
    }
    
    static var baseURL: String {
        let url = configManager.selectedProfile?.baseURL ?? ""
        // Ensure we have a valid base URL, defaulting to DeepSeek if empty
        return url.isEmpty ? "https://api.deepseek.com/v1" : url
    }
    
    // Add model configuration
    static var model: String {
        configManager.selectedProfile?.model ?? "gpt-3.5-turbo"
    }
    
    static func setModel(_ model: String) {
        if var profile = configManager.selectedProfile {
            profile.model = model
            configManager.selectedProfile = profile
        }
    }
    
    // Add temperature configuration
    static var temperature: Double {
        configManager.selectedProfile?.temperature ?? 0.7
    }
    
    static func setTemperature(_ temp: Double) {
        if var profile = configManager.selectedProfile {
            profile.temperature = temp
            configManager.selectedProfile = profile
        }
    }
} 