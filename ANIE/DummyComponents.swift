import Foundation
import CoreML

public class DummyPreprocessor {
    public init() {}
    
    public func shouldProcessMessage(_ message: String) throws -> Bool {
        return true
    }
}

public class DummyEmbeddingsGenerator {
    public init() {}
    
    public func generateEmbeddings(for text: String) throws -> [Float] {
        return Array(repeating: 0.0, count: 10)
    }
}

public class DummyResponseCache {
    private let embeddingsGenerator: DummyEmbeddingsGenerator
    
    public init() {
        self.embeddingsGenerator = DummyEmbeddingsGenerator()
    }
    
    public func findSimilarResponse(for query: String, similarityThreshold: Float = 0.9) throws -> String? {
        return nil
    }
    
    public func cacheResponse(query: String, response: String) throws {
        // Do nothing
    }
} 