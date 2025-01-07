import Foundation

struct CachedResponse: Codable {
    let query: String
    let response: String
    let embeddings: [Float]
    let timestamp: Date
}

class ResponseCache {
    private var cache: [CachedResponse] = []
    private let embeddings: EmbeddingsGenerator?
    private let similarityThreshold: Float = 0.90
    private let cacheKey = "bert_response_cache"
    
    var threshold: Float {
        return similarityThreshold
    }
    
    init() {
        self.embeddings = EmbeddingsService.shared.generator
        loadCache()
    }
    
    // Add persistence methods
    private func loadCache() {
        if let data = UserDefaults.standard.data(forKey: cacheKey),
           let savedCache = try? JSONDecoder().decode([CachedResponse].self, from: data) {
            cache = savedCache
            print("📚 Loaded \(cache.count) items from BERT cache")
        }
    }
    
    private func saveCache() {
        if let data = try? JSONEncoder().encode(cache) {
            UserDefaults.standard.set(data, forKey: cacheKey)
            print("💾 Saved \(cache.count) items to BERT cache")
        }
    }
    
    func findSimilarResponse(for query: String) throws -> String? {
        guard let embeddings = self.embeddings else {
            print("⚠️ Embeddings generator not available")
            return nil
        }
        
        do {
            let queryEmbeddings = try embeddings.generateEmbeddings(for: query)
            
            // Find most similar cached response
            var bestMatch: (similarity: Float, response: String, query: String)? = nil
            
            for cached in cache {
                let similarity = cosineSimilarity(queryEmbeddings, cached.embeddings)
                print("📊 Cache comparison:")
                print("   Query: '\(query)'")
                print("   Cached: '\(cached.query)'")
                print("   Similarity: \(similarity)")
                
                if similarity > similarityThreshold {
                    if bestMatch == nil || similarity > bestMatch!.similarity {
                        bestMatch = (similarity, cached.response, cached.query)
                        print("✅ New best match found:")
                        print("   Original query: '\(cached.query)'")
                        print("   Similarity: \(similarity)")
                    }
                }
            }
            
            if let match = bestMatch {
                print("🎯 Using cached response:")
                print("   Query: '\(query)'")
                print("   Matched with: '\(match.query)'")
                print("   Similarity: \(match.similarity)")
                return match.response + "\n[Retrieved using BERT]"
            }
            
            print("❌ No similar responses found (threshold: \(similarityThreshold))")
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
            
            // Save cache after adding new item
            saveCache()
            
        } catch {
            print("⚠️ Failed to cache response: \(error.localizedDescription)")
        }
    }
    
    // Add cache management methods
    func clearCache() {
        // Clear in-memory cache
        cache.removeAll()
        
        // Clear persisted cache in UserDefaults
        UserDefaults.standard.removeObject(forKey: cacheKey)
        UserDefaults.standard.synchronize()
        
        print("🧹 Cleared BERT cache:")
        print("   • In-memory cache cleared")
        print("   • Persisted cache cleared")
        print("   • Total items: 0")
    }
    
    private func cosineSimilarity(_ a: [Float], _ b: [Float]) -> Float {
        guard a.count == b.count && !a.isEmpty else { return 0 }
        
        let dotProduct = zip(a, b).map(*).reduce(0, +)
        let normA = sqrt(a.map { $0 * $0 }.reduce(0, +))
        let normB = sqrt(b.map { $0 * $0 }.reduce(0, +))
        
        return dotProduct / (normA * normB)
    }
    
    func getCacheSize() -> Int {
        return cache.count
    }
} 
