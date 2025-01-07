import Foundation

struct CachedResponse {
    let query: String
    let response: String
    let embeddings: [Float]
    let timestamp: Date
}

class ResponseCache {
    private var cache: [CachedResponse] = []
    private let embeddings: EmbeddingsGenerator?
    private let similarityThreshold: Float = 0.70  // Changed from 0.85
    
    init() {
        self.embeddings = EmbeddingsService.shared.generator
    }
    
    func findSimilarResponse(for query: String) throws -> String? {
        guard let embeddings = self.embeddings else {
            print("⚠️ Embeddings generator not available")
            return nil
        }
        
        do {
            let queryEmbeddings = try embeddings.generateEmbeddings(for: query)
            
            // Find most similar cached response
            var bestMatch: (similarity: Float, response: String)? = nil
            
            for cached in cache {
                let similarity = cosineSimilarity(queryEmbeddings, cached.embeddings)
                print("📊 Similarity score: \(similarity) for cached query: \(cached.query)")
                
                if similarity > similarityThreshold {
                    if bestMatch == nil || similarity > bestMatch!.similarity {
                        bestMatch = (similarity, cached.response)
                        print("✅ Found cache match with similarity: \(similarity)")
                    }
                }
            }
            
            if let match = bestMatch {
                print("🎯 Using cached response with similarity: \(match.similarity)")
                return match.response + "\n[Retrieved using BERT]"
            }
            
            print("❌ No similar responses found in cache (threshold: \(similarityThreshold))")
            return nil
            
        } catch {
            print("⚠️ Error generating embeddings: \(error.localizedDescription)")
            return nil
        }
    }
    
    func cacheResponse(query: String, response: String) throws {
        guard let embeddings = self.embeddings else {
            print("⚠️ Cannot cache: embeddings generator not available")
            return
        }
        
        do {
            let queryEmbeddings = try embeddings.generateEmbeddings(for: query)
            
            let cachedResponse = CachedResponse(
                query: query,
                response: response,
                embeddings: queryEmbeddings,
                timestamp: Date()
            )
            
            cache.append(cachedResponse)
            print("✅ Cached new response for query: \(query)")
            print("📊 Total cached items: \(cache.count)")
            
        } catch {
            print("⚠️ Failed to cache response: \(error.localizedDescription)")
        }
    }
    
    private func cosineSimilarity(_ a: [Float], _ b: [Float]) -> Float {
        guard a.count == b.count && !a.isEmpty else { return 0 }
        
        let dotProduct = zip(a, b).map(*).reduce(0, +)
        let normA = sqrt(a.map { $0 * $0 }.reduce(0, +))
        let normB = sqrt(b.map { $0 * $0 }.reduce(0, +))
        
        return dotProduct / (normA * normB)
    }
} 
