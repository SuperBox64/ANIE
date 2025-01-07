import Foundation
import CoreML

// MARK: - ML Device Capabilities
public struct MLDeviceCapabilities {
    public static var hasANE: Bool {
        if #available(iOS 14.0, macOS 11.0, *) {
            let supportedUnits = MLComputeUnits.all
            return supportedUnits.rawValue & MLComputeUnits.cpuAndNeuralEngine.rawValue != 0
        }
        return false
    }
    
    public static func getOptimalComputeUnits() -> MLComputeUnits {
        if hasANE {
            return .all
        }
        return .cpuAndGPU
    }
    
    public static func debugComputeInfo() {
        print("ANE Available: \(hasANE)")
        print("Optimal Compute Units: \(getOptimalComputeUnits())")
        
        if #available(iOS 14.0, macOS 11.0, *) {
            print("Supported Units: \(MLComputeUnits.all)")
        }
    }
    
    public static func runModelTests() -> String {
        var result = "=== ML System Test Results ===\n"
        result += "ANE Available: \(hasANE)\n"
        result += "Current Compute Units: \(getOptimalComputeUnits())\n"
        return result
    }
}

// MARK: - Embeddings Generator
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

// MARK: - Message Preprocessor
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

// MARK: - Response Cache
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

// MARK: - Errors
public enum MLError: Error {
    case modelNotFound
    case modelLoadFailed(Error)
    case predictionFailed
} 