import Foundation
import CoreML
import CryptoKit

// MARK: - Core Types
public struct Message: Codable {
    public let content: String
    public let isUser: Bool
    public let timestamp: Date
    
    public init(content: String, isUser: Bool, timestamp: Date = Date()) {
        self.content = content
        self.isUser = isUser
        self.timestamp = timestamp
    }
}

public struct ChatSession: Identifiable, Codable {
    public let id: UUID
    public var subject: String
    public var messages: [Message]
    
    public init(id: UUID = UUID(), subject: String, messages: [Message] = []) {
        self.id = id
        self.subject = subject
        self.messages = messages
    }
}

// MARK: - Protocol
public protocol ChatGPTClient {
    func generateResponse(for message: String) async throws -> String
}

// MARK: - Errors
public enum ChatError: Error {
    case invalidURL
    case networkError(Error)
    case serverError(Int, String)
    case decodingError(Error)
}

public enum MLError: Error {
    case modelNotFound
    case modelLoadFailed(Error)
    case predictionFailed
}

// MARK: - Response Models
public struct ChatResponse: Codable {
    public let choices: [ChatChoice]
}

public struct ChatChoice: Codable {
    public let message: ChatMessage
}

public struct ChatMessage: Codable {
    public let content: String
    public let role: String
    
    public init(content: String, role: String) {
        self.content = content
        self.role = role
    }
}

// MARK: - ML Types
public class CustomMessagePreprocessor {
    private var model: MLModel?
    
    public init() throws {
        let config = MLModelConfiguration()
        config.computeUnits = .cpuAndGPU  // Default to CPU/GPU for now
        
        do {
            guard let modelURL = Bundle.main.url(forResource: "MessageClassifier", withExtension: "mlmodel") else {
                throw MLError.modelNotFound
            }
            model = try MLModel(contentsOf: modelURL, configuration: config)
            print("Classifier model loaded with compute units: \(config.computeUnits)")
        } catch {
            throw MLError.modelLoadFailed(error)
        }
    }
    
    public func shouldProcessMessage(_ message: String) throws -> Bool {
        guard let model = model else {
            throw MLError.modelNotFound
        }
        
        do {
            let input = try MLDictionaryFeatureProvider(dictionary: [
                "text": MLFeatureValue(string: message)
            ])
            
            let output = try model.prediction(from: input)
            
            guard let processingFeature = output.featureValue(for: "requiresProcessing") else {
                throw MLError.predictionFailed
            }
            
            return processingFeature.doubleValue > 0.5
        } catch {
            throw MLError.predictionFailed
        }
    }
}

public class EmbeddingsGenerator {
    private var model: MLModel?
    
    public init() throws {
        let config = MLModelConfiguration()
        config.computeUnits = .cpuAndGPU  // Default to CPU/GPU for now
        
        do {
            guard let modelURL = Bundle.main.url(forResource: "TextEmbeddings", withExtension: "mlmodel") else {
                throw MLError.modelNotFound
            }
            model = try MLModel(contentsOf: modelURL, configuration: config)
            print("Embeddings model loaded with compute units: \(config.computeUnits)")
        } catch {
            throw MLError.modelLoadFailed(error)
        }
    }
    
    public func generateEmbeddings(for text: String) throws -> [Float] {
        guard let model = model else {
            throw MLError.modelNotFound
        }
        
        do {
            let input = try MLDictionaryFeatureProvider(dictionary: [
                "text": MLFeatureValue(string: text)
            ])
            
            let output = try model.prediction(from: input)
            
            guard let embeddingsFeature = output.featureValue(for: "embeddings"),
                  let multiArray = embeddingsFeature.multiArrayValue else {
                throw MLError.predictionFailed
            }
            
            var embeddings = [Float]()
            for i in 0..<multiArray.count {
                embeddings.append(Float(truncating: multiArray[i]))
            }
            
            return embeddings
        } catch {
            throw MLError.predictionFailed
        }
    }
}

public class ResponseCache {
    private var cache: [(query: String, embedding: [Float], response: String)] = []
    private let embeddingsGenerator: EmbeddingsGenerator
    
    public init(embeddingsGenerator: EmbeddingsGenerator) {
        self.embeddingsGenerator = embeddingsGenerator
    }
    
    public func findSimilarResponse(for query: String, similarityThreshold: Float = 0.9) throws -> String? {
        let queryEmbedding = try embeddingsGenerator.generateEmbeddings(for: query)
        
        let mostSimilar = cache.map { entry -> (similarity: Float, response: String) in
            let similarity = cosineSimilarity(queryEmbedding, entry.embedding)
            return (similarity, entry.response)
        }.max { $0.similarity < $1.similarity }
        
        guard let result = mostSimilar,
              result.similarity >= similarityThreshold else {
            return nil
        }
        
        return result.response
    }
    
    public func cacheResponse(query: String, response: String) throws {
        let embedding = try embeddingsGenerator.generateEmbeddings(for: query)
        cache.append((query: query, embedding: embedding, response: response))
    }
    
    private func cosineSimilarity(_ a: [Float], _ b: [Float]) -> Float {
        let dotProduct = zip(a, b).map(*).reduce(0, +)
        let magnitudeA = sqrt(a.map { $0 * $0 }.reduce(0, +))
        let magnitudeB = sqrt(b.map { $0 * $0 }.reduce(0, +))
        return dotProduct / (magnitudeA * magnitudeB)
    }
}

// MARK: - Credentials
public class CredentialsManager: ObservableObject {
    @Published public var isConfigured: Bool {
        didSet {
            UserDefaults.standard.set(isConfigured, forKey: "isConfigured")
        }
    }
    
    private let keychainHelper = KeychainHelper.standard
    private let apiKeyKey = "openai-api-key"
    private let baseURLKey = "openai-base-url"
    
    public init() {
        self.isConfigured = UserDefaults.standard.bool(forKey: "isConfigured")
    }
    
    public func saveCredentials(apiKey: String, baseURL: String) throws {
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
        
        isConfigured = true
    }
    
    public func getCredentials() -> (apiKey: String, baseURL: String)? {
        guard let keyString = UserDefaults.standard.string(forKey: "credentials-key"),
              let keyData = Data(base64Encoded: keyString),
              let apiKeyData = keychainHelper.read(service: apiKeyKey, account: "ANIE"),
              let baseURLData = keychainHelper.read(service: baseURLKey, account: "ANIE") else {
            return nil
        }
        
        let key = SymmetricKey(data: keyData)
        
        guard let apiKey = try? decrypt(sealed: apiKeyData, using: key),
              let baseURL = try? decrypt(sealed: baseURLData, using: key) else {
            return nil
        }
        
        return (apiKey, baseURL)
    }
    
    public func clearCredentials() {
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
}

// MARK: - Keychain Helper
public class KeychainHelper {
    public static let standard = KeychainHelper()
    private init() {}
    
    public func save(_ data: Data, service: String, account: String) {
        let query = [
            kSecValueData: data,
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
        ] as CFDictionary
        
        // Add data in keychain
        let status = SecItemAdd(query, nil)
        
        if status == errSecDuplicateItem {
            // Item already exists, thus update it
            let query = [
                kSecClass: kSecClassGenericPassword,
                kSecAttrService: service,
                kSecAttrAccount: account,
            ] as CFDictionary
            
            let attributesToUpdate = [kSecValueData: data] as CFDictionary
            
            // Update existing item
            SecItemUpdate(query, attributesToUpdate)
        }
    }
    
    public func read(service: String, account: String) -> Data? {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecReturnData: true
        ] as CFDictionary
        
        var result: AnyObject?
        SecItemCopyMatching(query, &result)
        
        return (result as? Data)
    }
    
    public func delete(service: String, account: String) {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
        ] as CFDictionary
        
        SecItemDelete(query)
    }
} 