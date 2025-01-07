import CoreML

enum PreprocessorError: Error {
    case modelNotFound
    case predictionFailed
}

// Change struct to class for MLFeatureProvider conformance
class MessageClassifierInput: MLFeatureProvider {
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

// Change from struct to class
class MessageClassifierOutput: MLFeatureProvider {
    let requiresProcessing: Double
    
    init(requiresProcessing: Double) {
        self.requiresProcessing = requiresProcessing
    }
    
    var featureNames: Set<String> {
        return ["requiresProcessing"]
    }
    
    func featureValue(for featureName: String) -> MLFeatureValue? {
        if featureName == "requiresProcessing" {
            return MLFeatureValue(double: requiresProcessing)
        }
        return nil
    }
}

class MessagePreprocessor {
    private let classifier: MLModel
    
    init() throws {
        guard let modelURL = Bundle.main.url(forResource: "MessageClassifier", withExtension: "mlmodel") else {
            throw PreprocessorError.modelNotFound
        }
        
        // Try ANE first, fallback to CPU/GPU if not available
        let config = MLModelConfiguration()
        config.computeUnits = .all
        
        do {
            // Try loading with ANE support
            self.classifier = try MLModel(contentsOf: modelURL, configuration: config)
            print("Classifier loaded with ANE support")
        } catch {
            // Fallback to CPU/GPU
            config.computeUnits = .cpuAndGPU
            guard let fallbackModel = try? MLModel(contentsOf: modelURL, configuration: config) else {
                throw PreprocessorError.modelNotFound
            }
            self.classifier = fallbackModel
            print("Classifier loaded in legacy mode (CPU/GPU)")
        }
    }
    
    func shouldProcessMessage(_ message: String) throws -> Bool {
        let input = MessageClassifierInput(text: message)
        let prediction = try classifier.prediction(from: input)
        
        // Simplify the prediction extraction
        guard let processingFeature = prediction.featureValue(for: "requiresProcessing") else {
            throw PreprocessorError.predictionFailed
        }
        
        return processingFeature.doubleValue > 0.7
    }
} 
