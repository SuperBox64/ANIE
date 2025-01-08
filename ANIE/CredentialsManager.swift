import Foundation
import CryptoKit

class CredentialsManager: ObservableObject {
    @Published var isConfigured: Bool {
        didSet {
            UserDefaults.standard.set(isConfigured, forKey: "isConfigured")
        }
    }
    
    private let keychainHelper = KeychainHelper.standard
    private let apiKeyKey = "llm-api-key"
    private let baseURLKey = "llm-base-url"
    
    init() {
        self.isConfigured = UserDefaults.standard.bool(forKey: "isConfigured")
    }
    
    func saveCredentials(apiKey: String, baseURL: String) throws {
        // Validate inputs
        guard !baseURL.isEmpty else {
            throw CredentialError.invalidBaseURL
        }
        
        // Clear old credentials first
        clearCredentials()
        
        // Generate a new key for encryption
        let key = SymmetricKey(size: .bits256)
        
        // Convert key to base64 string for storage
        let keyData = key.withUnsafeBytes { Data($0) }
        let keyString = keyData.base64EncodedString()
        
        // Store the encryption key
        UserDefaults.standard.set(keyString, forKey: "credentials-key")
        
        // Encrypt and store API key
        if let sealedAPIKey = try? encrypt(string: apiKey, using: key) {
            keychainHelper.save(sealedAPIKey, service: apiKeyKey, account: "ANIE")
        }
        
        // Encrypt and store base URL
        if let sealedBaseURL = try? encrypt(string: baseURL, using: key) {
            keychainHelper.save(sealedBaseURL, service: baseURLKey, account: "ANIE")
        }
        
        print("Debug: Saving baseURL: \(baseURL)") // Add debug print
        
        isConfigured = true
        
        // Update active LLMModelHandler instance with new credentials
        NotificationCenter.default.post(
            name: Notification.Name("CredentialsDidChange"),
            object: nil,
            userInfo: ["apiKey": apiKey, "baseURL": baseURL]
        )
    }
    
    func getCredentials() -> (apiKey: String, baseURL: String)? {
        guard let keyString = UserDefaults.standard.string(forKey: "credentials-key"),
              let keyData = Data(base64Encoded: keyString),
              let apiKeyData = keychainHelper.read(service: apiKeyKey, account: "ANIE"),
              let baseURLData = keychainHelper.read(service: baseURLKey, account: "ANIE") else {
            print("Debug: Failed to read credentials")
            return nil
        }
        
        let key = SymmetricKey(data: keyData)
        
        guard let apiKey = try? decrypt(sealed: apiKeyData, using: key),
              let baseURL = try? decrypt(sealed: baseURLData, using: key) else {
            print("Debug: Failed to decrypt credentials")
            return nil
        }
        
        print("Debug: Retrieved baseURL: \(baseURL)")
        return (apiKey, baseURL)
    }
    
    func clearCredentials() {
        keychainHelper.delete(service: apiKeyKey, account: "ANIE")
        keychainHelper.delete(service: baseURLKey, account: "ANIE")
        UserDefaults.standard.removeObject(forKey: "credentials-key")
        isConfigured = false
    }
    
    private func encrypt(string: String, using key: SymmetricKey) throws -> Data {
        let data = string.data(using: .utf8)!
        let sealedBox = try AES.GCM.seal(data, using: key)
        return sealedBox.combined!
    }
    
    private func decrypt(sealed: Data, using key: SymmetricKey) throws -> String {
        let sealedBox = try AES.GCM.SealedBox(combined: sealed)
        let decryptedData = try AES.GCM.open(sealedBox, using: key)
        return String(data: decryptedData, encoding: .utf8)!
    }
    
    // Add error enum
    enum CredentialError: Error {
        case invalidBaseURL
    }
} 