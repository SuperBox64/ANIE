import Foundation

struct CachedResponse: Codable {
    let query: String
    let response: String
    let embeddings: [Float]
    let timestamp: Date
    let sessionId: UUID
    var isOmitted: Bool  // Add isOmitted flag to cached responses
}

class ResponseCache {
    static let shared = ResponseCache()
    
    private var cache: [CachedResponse] = []
    private let embeddings: EmbeddingsGenerator?
    private let similarityThreshold: Float = 0.95
    private let cacheKey = "bert_response_cache"
    private let maxLengthDifference = 0.1
    
    var threshold: Float {
        return similarityThreshold
    }
    
    private init() {
        self.embeddings = EmbeddingsService.shared.generator
        loadCache()
        expireOldCacheEntries()
    }
    
    // Add persistence methods
    private func loadCache() {
        print("📂 Loading BERT cache")
        if let data = UserDefaults.standard.data(forKey: cacheKey),
           let savedCache = try? JSONDecoder().decode([CachedResponse].self, from: data) {
            let expirationDate = Date().addingTimeInterval(-24 * 60 * 60) // 24 hours ago
            
            // Load, filter expired items, and remove omitted responses in one pass
            cache = savedCache.filter { item in
                let isValid = !item.isOmitted && item.timestamp > expirationDate
                return isValid
            }
            
            // Only save if we filtered out any items
            if savedCache.count != cache.count {
                print("🕒 Filtered out \(savedCache.count - cache.count) expired/omitted items")
                saveCache()
            }
            
            print("📚 Loaded \(cache.count) active items in BERT cache")
            
            // Print age summary of remaining items
            let oldestTimestamp = cache.map { $0.timestamp }.min() ?? Date()
            let newestTimestamp = cache.map { $0.timestamp }.max() ?? Date()
            print("📊 Cache age summary:")
            print("   • Oldest item: \(String(format: "%.1f", Date().timeIntervalSince(oldestTimestamp) / 3600)) hours old")
            print("   • Newest item: \(String(format: "%.1f", Date().timeIntervalSince(newestTimestamp) / 3600)) hours old")
        } else {
            print("   No saved cache found")
        }
    }
    
    private func saveCache() {
        // Filter out omitted responses one final time before saving
        let nonOmittedCache = cache.filter { !$0.isOmitted }
        if let data = try? JSONEncoder().encode(nonOmittedCache) {
            UserDefaults.standard.set(data, forKey: cacheKey)
            UserDefaults.standard.synchronize() // Force immediate write
            print("💾 Saved \(nonOmittedCache.count) items to BERT cache")
        }
    }
    
    private func expireOldCacheEntries() {
        let expirationDate = Date().addingTimeInterval(-24 * 60 * 60) // 24 hours ago
        let beforeCount = cache.count
        
        // Remove expired and omitted items in one pass
        cache = cache.filter { 
            !$0.isOmitted && $0.timestamp > expirationDate
        }
        
        // Only save if we actually removed entries
        if beforeCount != cache.count {
            let removedCount = beforeCount - cache.count
            print("🕒 Expired \(removedCount) old/omitted cache entries")
            saveCache()
        }
    }
    
    func findSimilarResponse(for query: String, sessionId: UUID) throws -> String? {
        // Aggressively purge omitted responses before searching
        purgeOmittedResponses(for: sessionId)
        
        guard let embeddings = self.embeddings else {
            print("⚠️ Embeddings generator not available")
            return nil
        }
        
        // Get session responses FIRST and exit early if empty
        let sessionResponses = cache.filter { $0.sessionId == sessionId && !$0.isOmitted }
        
        // Early exit if no history for this session
        if sessionResponses.isEmpty {
            print("📝 No cache history for session \(sessionId)")
            return nil
        }
        
        print("🔍 Searching through \(sessionResponses.count) cached responses for session \(sessionId)")
        
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
            
            // Only use responses from the filtered session list
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
                if lengthRatio < (1.0 - maxLengthDifference) {
                    print("📏 Length mismatch for cached query: '\(normalizedCachedQuery)'")
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
                
                // Much stricter word overlap requirement
                if overlapRatio < 0.8 {
                    print("📚 Low word overlap for cached query: '\(normalizedCachedQuery)'")
                    print("   Overlap ratio: \(Int(overlapRatio * 100))%")
                    continue
                }
                
                let similarity = cosineSimilarity(queryEmbeddings, cached.embeddings)
                print("📊 Cache comparison:")
                print("   Query: '\(normalizedQuery)'")
                print("   Cached: '\(normalizedCachedQuery)'")
                print("   Similarity: \(similarity)")
                print("   Word overlap: \(Int(overlapRatio * 100))%")
                
                // Remove leniency for high word overlap - always use strict threshold
                if similarity > similarityThreshold {
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
                if isErrorResponse(match.response) {
                    print("⚠️ Cached response is an error, fetching new response from LLM")
                    return nil // Indicate that a new call should be made
                }
                print("🎯 Using cached response:")
                print("   Query: '\(normalizedQuery)'")
                print("   Matched with: '\(match.query)'")
                print("   Similarity: \(match.similarity)")
                return match.response + "\n[Retrieved using BERT]"
            }
            
            print("❌ No similar responses found in session \(sessionId) (threshold: \(similarityThreshold))")
            return nil
            
        } catch {
            print("⚠️ Error generating embeddings: \(error.localizedDescription)")
            return nil
        }
    }
    
    func cacheResponse(query: String, response: String, sessionId: UUID, isOmitted: Bool = false) throws {
        // Aggressively purge omitted responses first
        purgeOmittedResponses(for: sessionId)
        
        guard let embeddings = self.embeddings else {
            print("⚠️ Cannot cache: embeddings generator not available")
            return
        }
        
        if isErrorResponse(response) {
            print("⚠️ Not caching error response for query: \(query)")
            return
        }
        
        // Don't cache omitted responses
        if isOmitted {
            print("⚠️ Not caching omitted response for query: \(query)")
            purgeOmittedResponses(for: sessionId) // Double check purge
            return
        }
        
        do {
            let queryEmbeddings = try embeddings.generateEmbeddings(for: query)
            
            // Double check no omitted responses exist for this session
            cache = cache.filter { !($0.sessionId == sessionId && $0.isOmitted) }
            
            let cachedResponse = CachedResponse(
                query: query,
                response: response,
                embeddings: queryEmbeddings,
                timestamp: Date(),
                sessionId: sessionId,
                isOmitted: isOmitted
            )
            
            cache.append(cachedResponse)
            expireOldCacheEntries() // This will also save the cache
            print("✅ Cached new response for query: \(query)")
            print("📊 Total cached items: \(cache.count)")
            
        } catch {
            print("⚠️ Failed to cache response: \(error.localizedDescription)")
        }
    }
    
    // Helper method to determine if a response is an error
    private func isErrorResponse(_ response: String) -> Bool {
        // Implement logic to determine if the response is an error
        // For example, check if the response contains specific error keywords
        return response.contains("error") || response.contains("failed")
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
    
    // Add method to purge omitted responses for a session
    func purgeOmittedResponses(for sessionId: UUID) {
        let beforeCount = cache.count
        
        // Aggressively remove omitted responses from memory
        cache = cache.filter { !$0.isOmitted } // Remove all omitted responses
        cache = cache.filter { !($0.sessionId == sessionId && $0.isOmitted) } // Double check session-specific
        
        // Force save the updated cache
        saveCache()
        UserDefaults.standard.synchronize()
        
        let afterCount = cache.count
        let removedCount = beforeCount - afterCount
        
        print("🧹 Purged omitted responses:")
        print("   • Before: \(beforeCount) items")
        print("   • After: \(afterCount) items")
        print("   • Removed: \(removedCount) items")
        print("   • Session: \(sessionId)")
    }
    
    // Add method to force purge all omitted responses
    func forcePurgeAllOmittedResponses() {
        let beforeCount = cache.count
        
        // Aggressively remove all omitted responses
        cache = cache.filter { !$0.isOmitted }
        
        // Force save
        saveCache()
        UserDefaults.standard.synchronize()
        
        let afterCount = cache.count
        let removedCount = beforeCount - afterCount
        
        print("🧹 Force purged ALL omitted responses:")
        print("   • Before: \(beforeCount) items")
        print("   • After: \(afterCount) items")
        print("   • Removed: \(removedCount) items")
    }
    
    // Add method to completely delete all cached responses for a session
    func deleteEntireSessionCache(for sessionId: UUID) {
        let beforeCount = cache.count
        
        // Remove ALL responses for this session, regardless of omitted state
        cache = cache.filter { $0.sessionId != sessionId }
        
        // Force save the updated cache
        saveCache()
        UserDefaults.standard.synchronize()
        
        let afterCount = cache.count
        let removedCount = beforeCount - afterCount
        
        print("🧹 DELETED ENTIRE SESSION CACHE:")
        print("   • Session: \(sessionId)")
        print("   • Before: \(beforeCount) items")
        print("   • After: \(afterCount) items")
        print("   • Removed: \(removedCount) items")
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
