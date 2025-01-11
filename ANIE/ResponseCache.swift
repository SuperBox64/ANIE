import Foundation

struct CachedResponse: Codable {
    let query: String
    let response: String
    let embeddings: [Float]
    let timestamp: Date
    let sessionId: UUID
}

class ResponseCache {
    static let shared = ResponseCache()
    
    private var cache: [CachedResponse] = []
    private let embeddings: EmbeddingsGenerator?
    private let similarityThreshold: Float = 0.8
    private let cacheKey = "bert_response_cache"
    private let maxLengthDifference = 0.2
    
    var threshold: Float {
        return similarityThreshold
    }
    
    private init() {
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
    
    func findSimilarResponse(for query: String, sessionId: UUID) throws -> String? {
        guard let embeddings = self.embeddings else {
            print("⚠️ Embeddings generator not available")
            return nil
        }
        
        do {
            // Normalize query by:
            // 1. Trimming whitespace and standardizing line endings
            // 2. Removing punctuation
            // 3. Converting to lowercase
            let normalizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
                                     .replacingOccurrences(of: "\r\n", with: "\n")
                                     .replacingOccurrences(of: "\r", with: "\n")
                                     .components(separatedBy: .punctuationCharacters).joined(separator: " ")
                                     .lowercased()
                                     .components(separatedBy: .whitespaces)
                                     .filter { !$0.isEmpty }
                                     .joined(separator: " ")
            
            let queryEmbeddings = try embeddings.generateEmbeddings(for: normalizedQuery)
            let queryWords = normalizedQuery.split(separator: " ").map(String.init)
            
            // Find most similar cached response
            var bestMatch: (similarity: Float, response: String, query: String)? = nil
            
            // Only look at responses from the same session
            let sessionResponses = cache.filter { $0.sessionId == sessionId }
            
            for cached in sessionResponses {
                // Normalize cached query the same way
                let normalizedCachedQuery = cached.query.trimmingCharacters(in: .whitespacesAndNewlines)
                                                      .replacingOccurrences(of: "\r\n", with: "\n")
                                                      .replacingOccurrences(of: "\r", with: "\n")
                                                      .components(separatedBy: .punctuationCharacters).joined(separator: " ")
                                                      .lowercased()
                                                      .components(separatedBy: .whitespaces)
                                                      .filter { !$0.isEmpty }
                                                      .joined(separator: " ")
                
                // Check length similarity first
                let cachedWords = normalizedCachedQuery.split(separator: " ").map(String.init)
                let lengthRatio = Double(min(queryWords.count, cachedWords.count)) / 
                                Double(max(queryWords.count, cachedWords.count))
                
                // Be more lenient with length differences
                if lengthRatio < (1.0 - maxLengthDifference * 1.5) {
                    print("📏 Length mismatch:")
                    print("   Query words: \(queryWords.count)")
                    print("   Cached words: \(cachedWords.count)")
                    continue
                }
                
                // Calculate word overlap with common variations
                var commonWords = Set(queryWords).intersection(Set(cachedWords))
                
                // Add common word variations (you could expand this list)
                let variations = [
                    "dont": "don't",
                    "cant": "can't",
                    "whats": "what's",
                    "im": "i'm",
                    "ive": "i've",
                    "id": "i'd",
                    "youre": "you're",
                    "youve": "you've",
                    "youll": "you'll",
                    "theyre": "they're",
                    "wont": "won't",
                    "isnt": "isn't",
                    "arent": "aren't",
                    "hasnt": "hasn't",
                    "havent": "haven't",
                    "couldnt": "couldn't",
                    "wouldnt": "wouldn't",
                    "shouldnt": "shouldn't"
                ]
                
                // Add variations to common words
                for word in queryWords {
                    if let variation = variations[word] {
                        if cachedWords.contains(variation) {
                            commonWords.insert(word)
                        }
                    }
                }
                
                let overlapRatio = Double(commonWords.count) / Double(queryWords.count)
                
                // Be more lenient with word overlap
                if overlapRatio < 0.5 {  // Reduced from 0.7 to 0.5 (50% word overlap required)
                    print("📚 Low word overlap: \(Int(overlapRatio * 100))%")
                    continue
                }
                
                let similarity = cosineSimilarity(queryEmbeddings, cached.embeddings)
                print("📊 Cache comparison:")
                print("   Query: '\(normalizedQuery)'")
                print("   Cached: '\(normalizedCachedQuery)'")
                print("   Similarity: \(similarity)")
                print("   Word overlap: \(Int(overlapRatio * 100))%")
                
                // Be slightly more lenient with similarity threshold for high word overlap
                let adjustedThreshold = overlapRatio > 0.8 ? similarityThreshold * 0.9 : similarityThreshold
                
                if similarity > adjustedThreshold {
                    if bestMatch == nil || similarity > bestMatch!.similarity {
                        bestMatch = (similarity, cached.response, normalizedCachedQuery)
                        print("✅ New best match found:")
                        print("   Original query: '\(normalizedCachedQuery)'")
                        print("   Similarity: \(similarity)")
                        print("   Word overlap: \(Int(overlapRatio * 100))%")
                    }
                }
            }
            
            if let match = bestMatch {
                print("🎯 Using cached response:")
                print("   Query: '\(normalizedQuery)'")
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
    
    func cacheResponse(query: String, response: String, sessionId: UUID) throws {
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
                timestamp: Date(),
                sessionId: sessionId
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
