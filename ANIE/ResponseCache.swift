import CoreML

class ResponseCache {
    private var cache: [(query: String, embedding: [Float], response: String)] = []
    private let embeddingsGenerator: EmbeddingsGenerator
    
    init(embeddingsGenerator: EmbeddingsGenerator) {
        self.embeddingsGenerator = embeddingsGenerator
    }
    
    func findSimilarResponse(for query: String, similarityThreshold: Float = 0.9) throws -> String? {
        let queryEmbedding = try embeddingsGenerator.generateEmbeddings(for: query)
        
        // Find most similar cached query
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
    
    func cacheResponse(query: String, response: String) throws {
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
