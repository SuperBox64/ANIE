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

// Output can remain a struct
struct MessageClassifierOutput {
    let requiresProcessing: Double
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
        guard let output = try? classifier.prediction(from: input) as? MessageClassifierOutput else {
            throw PreprocessorError.predictionFailed
        }
        
        // Based on the classification, determine if the message needs API processing
        return output.requiresProcessing > 0.7 // threshold
    }
} 