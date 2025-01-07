import CoreML
import NaturalLanguage

class TextEmbeddingsInput: MLFeatureProvider {
    let text: String
    
    init(text: String) {
        self.text = text
    }
    
    var featureNames: Set<String> {
        return ["text"]
    }
    
    func featureValue(for featureName: String) -> MLFeatureValue? {
        if featureName == "text" {
            return MLFeatureValue(string: text)
        }
        return nil
    }
}

class TextEmbeddingsOutput: MLFeatureProvider {
    let embeddings: [Float]
    
    init(embeddings: [Float]) {
        self.embeddings = embeddings
    }
    
    var featureNames: Set<String> {
        return ["embeddings"]
    }
    
    func featureValue(for featureName: String) -> MLFeatureValue? {
        if featureName == "embeddings" {
            let shape = [NSNumber(value: embeddings.count)]
            let array = try! MLMultiArray(shape: shape, dataType: .float32)
            for (index, value) in embeddings.enumerated() {
                array[index] = NSNumber(value: value)
            }
            return MLFeatureValue(multiArray: array)
        }
        return nil
    }
}

class EmbeddingsGenerator {
    private let embedder: NLEmbedding?
    private let modelVersion: String = "1.0"
    private let maxTokenLength = 512  // BERT's typical max token length
    
    init() throws {
        // Try to load Apple's built-in BERT model
        guard let embedding = NLEmbedding.wordEmbedding(for: .english) else {
            print("⚠️ Failed to load word embedding model")
            throw EmbeddingsError.modelNotFound
        }
        self.embedder = embedding
        print("✅ Successfully loaded word embedding model with dimension: \(embedding.dimension)")
        
        // Print model capabilities
        let config = MLModelConfiguration()
        config.computeUnits = .all
        print("Model compute units: \(config.computeUnits.rawValue)")
        print("ANE available: \(MLDeviceCapabilities.hasANE)")
    }
    
    func generateEmbeddings(for text: String) throws -> [Float] {
        guard let embedder = embedder else {
            throw EmbeddingsError.modelNotFound
        }
        
        // Log BERT usage
        EmbeddingsService.shared.logUsage(operation: "Generate embeddings for: \(text.prefix(30))...")
        
        // Preprocess text
        let processedText = preprocess(text)
        
        // Split into words and normalize
        let words = processedText.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .map { $0.lowercased() }
        
        guard !words.isEmpty else {
            throw EmbeddingsError.invalidInput
        }
        
        // Initialize vector with zeros
        var sumVector: [Double] = Array(repeating: 0, count: embedder.dimension)
        var validWordCount = 0
        
        // Try different approaches to get embeddings for each word
        for word in words {
            if let vector = embedder.vector(for: word) {
                // Direct word match
                for (index, value) in vector.enumerated() {
                    sumVector[index] += value
                }
                validWordCount += 1
            } else if let vector = embedder.vector(for: word) {
                // Try as phrase
                for (index, value) in vector.enumerated() {
                    sumVector[index] += value
                }
                validWordCount += 1
            } else {
                // Try subwords if word is long enough
                let subwords = word.split(separator: " ")
                for subword in subwords {
                    if let vector = embedder.vector(for: String(subword)) {
                        for (index, value) in vector.enumerated() {
                            sumVector[index] += value
                        }
                        validWordCount += 1
                    }
                }
            }
        }
        
        // If we got at least one valid embedding, return the average
        guard validWordCount > 0 else {
            print("⚠️ No valid embeddings found for text: \(processedText)")
            // Return zero vector instead of throwing error
            return Array(repeating: 0, count: embedder.dimension)
        }
        
        // Average the vectors and convert to Float
        let embeddings = sumVector.map { Float($0 / Double(validWordCount)) }
        print("✅ Generated embeddings with \(validWordCount) valid words")
        
        return embeddings
    }
    
    private func preprocess(_ text: String) -> String {
        // Basic preprocessing
        var processed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        processed = processed.lowercased()
        
        // Truncate if needed
        let words = processed.split(separator: " ")
        if words.count > maxTokenLength {
            processed = words.prefix(maxTokenLength).joined(separator: " ")
        }
        
        return processed
    }
    
    func modelInfo() -> [String: Any] {
        return [
            "version": modelVersion,
            "maxTokenLength": maxTokenLength,
            "supportsANE": MLDeviceCapabilities.hasANE,
            "computeUnits": MLDeviceCapabilities.getOptimalComputeUnits(),
            "embeddingDimension": embedder?.dimension ?? 0
        ]
    }
}

enum EmbeddingsError: Error {
    case modelNotFound
    case predictionFailed
    case emptyEmbeddings
    case tokenLengthExceeded
    case invalidInput
    
    var localizedDescription: String {
        switch self {
        case .modelNotFound:
            return "Embedding model could not be loaded"
        case .predictionFailed:
            return "Failed to generate embeddings"
        case .emptyEmbeddings:
            return "Generated embeddings are empty"
        case .tokenLengthExceeded:
            return "Input text exceeds maximum token length"
        case .invalidInput:
            return "Invalid input text"
        }
    }
} 
