import CoreML

// Change struct to class for MLFeatureProvider conformance
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

// Output can remain a struct
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
    private let model: MLModel
    
    init() throws {
        guard let modelURL = Bundle.main.url(forResource: "TextEmbeddings", withExtension: "mlmodel") else {
            throw EmbeddingsError.modelNotFound
        }
        
        // Try ANE first, fallback to CPU/GPU if not available
        let config = MLModelConfiguration()
        config.computeUnits = .all
        
        do {
            // Try loading with ANE support
            self.model = try MLModel(contentsOf: modelURL, configuration: config)
            print("Model loaded with ANE support")
        } catch {
            // Fallback to CPU/GPU
            config.computeUnits = .cpuAndGPU
            guard let fallbackModel = try? MLModel(contentsOf: modelURL, configuration: config) else {
                throw EmbeddingsError.modelNotFound
            }
            self.model = fallbackModel
            print("Model loaded in legacy mode (CPU/GPU)")
        }
    }
    
    func generateEmbeddings(for text: String) throws -> [Float] {
        let input = TextEmbeddingsInput(text: text)
        let prediction = try model.prediction(from: input)
        
        guard let embeddingsFeature = prediction.featureValue(for: "embeddings"),
              let multiArray = embeddingsFeature.multiArrayValue else {
            throw EmbeddingsError.predictionFailed
        }
        
        var embeddings = [Float]()
        for i in 0..<multiArray.count {
            embeddings.append(Float(truncating: multiArray[i]))
        }
        
        return embeddings
    }
}

enum EmbeddingsError: Error {
    case modelNotFound
    case predictionFailed
} 
