import CoreML
import NaturalLanguage

class LocalAIHandler {
    private let tokenizer: NLTokenizer
    private let embeddingGenerator: EmbeddingsGenerator?
    private lazy var cache: ResponseCache = ResponseCache.shared
    
    init() {
        self.tokenizer = NLTokenizer(unit: .word)
        self.embeddingGenerator = EmbeddingsService.shared.generator
    }
    
    func generateResponse(for query: String) async throws -> String {
        print("🧠 LocalAI processing query...")
        
        // Check for special queries first
        if let specialResponse = handleSpecialQueries(query) {
            return specialResponse
        }
        
        // Try to find a cached response only for non-programming, non-AI/ML queries
        let lowercasedQuery = query.lowercased()
        let isProgrammingQuery = lowercasedQuery.contains("code") || 
                               lowercasedQuery.contains("programming") || 
                               lowercasedQuery.contains("swift") || 
                               lowercasedQuery.contains("function") ||
                               lowercasedQuery.contains("class") ||
                               lowercasedQuery.contains("struct")
        
        let isAIMLQuery = lowercasedQuery.contains("ai") ||
                         lowercasedQuery.contains("ml") ||
                         lowercasedQuery.contains("neural") ||
                         lowercasedQuery.contains("bert") ||
                         lowercasedQuery.contains("model")
        
        if !isProgrammingQuery && !isAIMLQuery {
            do {
                if let similarResponse = try cache.findSimilarResponse(for: query) {
                    print("🧠 LocalAI: Found cached response")
                    return similarResponse
                }
            } catch {
                print("🧠 LocalAI: Cache lookup failed, continuing with local response")
            }
        } else {
            print("🧠 LocalAI: Skipping cache for programming/AI/ML query")
        }
        
        // Generate a local response based on the query type
        let response = generateLocalResponse(for: query)
        
        // Skip caching for Local AI responses, programming queries, and AI/ML queries
        print("🧠 LocalAI: Response generated (not cached)")
        return response
    }
    
    private func handleSpecialQueries(_ query: String) -> String? {
        let lowercasedQuery = query.lowercased()
        
        // Creator/About queries
        if lowercasedQuery.contains("who made you") || 
           lowercasedQuery.contains("who created you") ||
           lowercasedQuery.contains("who is your creator") {
            return "I was created by Todd Bruss, an imaginative out of the box thinker."
        }
        
        // System capabilities
        if lowercasedQuery.contains("what can you do") ||
           lowercasedQuery.contains("your capabilities") ||
           lowercasedQuery.contains("help me") {
            return """
                I am ANIE (Artificial Neural Intelligence Engine), and I can help you with:
                - Answering questions about ML and AI
                - Providing information about the Apple Neural Engine
                - Explaining technical concepts
                - Basic calculations and analysis
                - Offering suggestions and recommendations
                
                I'm currently running in Local AI mode, which means I operate without network connectivity.
                """
        }
        
        // ML/AI specific queries
        if lowercasedQuery.contains("neural engine") ||
           lowercasedQuery.contains("ane") ||
           lowercasedQuery.contains("ml") ||
           lowercasedQuery.contains("bert") {
            let systemInfo = MLDeviceCapabilities.getSystemInfo()
            return generateMLResponse(query: lowercasedQuery, systemInfo: systemInfo)
        }
        
        return nil
    }
    
    private func generateLocalResponse(for query: String) -> String {
        let lowercasedQuery = query.lowercased()
        
        // Swift programming specific responses
        if lowercasedQuery.contains("swift") {
            if lowercasedQuery.contains("hello world") {
                return """
                    Here's a basic Swift Hello World program:
                    
                    ```swift
                    print("Hello, World!")
                    ```
                    
                    For a more SwiftUI version:
                    
                    ```swift
                    import SwiftUI
                    
                    struct ContentView: View {
                        var body: some View {
                            Text("Hello, World!")
                        }
                    }
                    ```
                    
                    Key concepts:
                    - print() is used for console output
                    - Text() is a SwiftUI view for displaying text
                    - struct ContentView: View defines a SwiftUI view
                    """
            }
            
            if lowercasedQuery.contains("struct") || lowercasedQuery.contains("class") {
                return """
                    In Swift, both structs and classes are used to define custom types:
                    
                    Struct example:
                    ```swift
                    struct Person {
                        let name: String
                        var age: Int
                        
                        func describe() -> String {
                            return "\\(name) is \\(age) years old"
                        }
                    }
                    ```
                    
                    Class example:
                    ```swift
                    class Animal {
                        var species: String
                        
                        init(species: String) {
                            self.species = species
                        }
                    }
                    ```
                    
                    Key differences:
                    - Structs are value types (copied when assigned)
                    - Classes are reference types (shared when assigned)
                    - Structs have automatic memberwise initializers
                    - Classes support inheritance
                    """
            }
            
            if lowercasedQuery.contains("function") || lowercasedQuery.contains("func") {
                return """
                    Swift functions are defined using the 'func' keyword:
                    
                    ```swift
                    // Basic function
                    func greet(name: String) -> String {
                        return "Hello, \\(name)!"
                    }
                    
                    // Function with multiple parameters
                    func calculate(a: Int, b: Int, operation: String) -> Int {
                        switch operation {
                        case "+": return a + b
                        case "-": return a - b
                        default: return 0
                        }
                    }
                    
                    // Function with default parameter
                    func welcome(name: String, greeting: String = "Hello") {
                        print("\\(greeting), \\(name)!")
                    }
                    ```
                    
                    Key features:
                    - Clear parameter labels
                    - Return type with ->
                    - Support for default values
                    - String interpolation with \\()
                    """
            }
            
            if lowercasedQuery.contains("array") || lowercasedQuery.contains("dictionary") {
                return """
                    Swift Collections Overview:
                    
                    Arrays:
                    ```swift
                    // Array declaration
                    var numbers = [1, 2, 3, 4, 5]
                    var names: [String] = []
                    
                    // Common operations
                    numbers.append(6)
                    numbers.insert(0, at: 0)
                    let first = numbers.first
                    let last = numbers.last
                    ```
                    
                    Dictionaries:
                    ```swift
                    // Dictionary declaration
                    var scores = ["John": 100, "Alice": 95]
                    var config: [String: Any] = [:]
                    
                    // Common operations
                    scores["Bob"] = 90
                    let johnScore = scores["John"]
                    scores.removeValue(forKey: "Alice")
                    ```
                    
                    Common methods:
                    - map, filter, reduce
                    - contains, forEach, sorted
                    - count, isEmpty
                    """
            }
            
            // Default Swift response
            return """
                Swift Programming Guide:
                
                Basic Concepts:
                ```swift
                // Variables and Constants
                var mutable = "Can change"
                let constant = "Can't change"
                
                // Types
                var string: String = "text"
                var number: Int = 42
                var decimal: Double = 3.14
                var flag: Bool = true
                
                // Control Flow
                if condition {
                    // code
                } else {
                    // code
                }
                
                for item in items {
                    // code
                }
                
                // Functions
                func doSomething(with parameter: String) -> String {
                    return parameter.uppercased()
                }
                ```
                
                What specific aspect would you like to learn about?
                - Variables and Types
                - Functions and Methods
                - Classes and Structs
                - SwiftUI Views
                - Protocols and Extensions
                """
        }
        
        // General programming concepts
        if lowercasedQuery.contains("code") || lowercasedQuery.contains("programming") {
            return """
                Programming Concepts Guide:
                
                1. Data Types:
                   - Strings: Text data
                   - Numbers: Integers and decimals
                   - Booleans: True/false values
                   - Arrays: Ordered collections
                   - Dictionaries: Key-value pairs
                
                2. Control Flow:
                   - If/else conditions
                   - Loops (for, while)
                   - Switch statements
                
                3. Functions:
                   - Input parameters
                   - Return values
                   - Scope and closure
                
                4. Object-Oriented Concepts:
                   - Classes and objects
                   - Inheritance
                   - Encapsulation
                   - Polymorphism
                
                5. Best Practices:
                   - Code organization
                   - Naming conventions
                   - Error handling
                   - Documentation
                
                What specific topic would you like to explore?
                """
        }
        
        // Technical questions about the system
        if lowercasedQuery.contains("how") || lowercasedQuery.contains("why") || lowercasedQuery.contains("what") {
            if lowercasedQuery.contains("neural") || lowercasedQuery.contains("ai") || lowercasedQuery.contains("ml") {
                return """
                    AI and Neural Networks in ANIE:
                    
                    1. Apple Neural Engine (ANE):
                       - Hardware acceleration for ML
                       - Optimized for neural networks
                       - Low power consumption
                       - High performance processing
                    
                    2. BERT Implementation:
                       - Text embeddings generation
                       - Semantic similarity matching
                       - Local processing capability
                       - Efficient caching system
                    
                    3. Local AI Features:
                       - Offline processing
                       - Response generation
                       - Pattern matching
                       - Context understanding
                    
                    4. ML Capabilities:
                       - Text analysis
                       - Semantic search
                       - Response caching
                       - Performance optimization
                    
                    Current System Status:
                    \(generateMLResponse(query: lowercasedQuery, systemInfo: MLDeviceCapabilities.getSystemInfo()))
                    """
            }
            
            if lowercasedQuery.contains("cache") || lowercasedQuery.contains("memory") {
                return """
                    ANIE's Caching System:
                    
                    1. BERT Embeddings:
                       - Converts text to numerical vectors
                       - 300-dimensional embeddings
                       - Semantic meaning preservation
                       - Fast similarity comparison
                    
                    2. Cache Structure:
                       - Query-response pairs
                       - Embedding vectors
                       - Similarity thresholds
                       - Persistence storage
                    
                    3. Matching Process:
                       - Semantic similarity check
                       - Threshold validation
                       - Response retrieval
                       - Cache updates
                    
                    Current Cache Stats:
                    - Size: \(cache.getCacheSize()) items
                    - Threshold: \(String(format: "%.2f", cache.threshold))
                    - BERT Status: \(EmbeddingsService.shared.generator != nil ? "Active" : "Inactive")
                    """
            }
        }
        
        // Default response with more context
        return """
            ANIE's Local AI Capabilities:
            
            1. Programming Help:
               - Swift syntax and examples
               - Code structure guidance
               - Best practices
               - Common patterns
            
            2. System Information:
               - ML/AI capabilities
               - Cache management
               - Performance metrics
               - Hardware utilization
            
            3. Technical Knowledge:
               - Neural networks
               - Machine learning
               - System architecture
               - Data processing
            
            4. Available Commands:
               - !ml status  (system status)
               - !ml clear   (clear cache)
               - !ml help    (show help)
            
            How can I assist you with these topics?
            """
    }
    
    private func generateMLResponse(query: String, systemInfo: [String: Any]) -> String {
        let hasANE = systemInfo["hasANE"] as? Bool ?? false
        let computeUnits = systemInfo["computeUnits"] as? Int ?? 0
        let modelActive = systemInfo["modelActive"] as? Bool ?? false
        
        var components = [String]()
        
        if hasANE {
            components.append("The Apple Neural Engine (ANE) is active and being used for ML acceleration")
            components.append("Current compute units: \(computeUnits)")
        } else {
            components.append("Running on CPU/GPU for ML computations")
        }
        
        if modelActive {
            components.append("BERT model is active and ready for embedding generation")
        }
        
        if let metrics = try? gatherPerformanceMetrics() {
            components.append(metrics)
        }
        
        return components.joined(separator: "\n")
    }
    
    private func gatherPerformanceMetrics() throws -> String {
        let start = CFAbsoluteTimeGetCurrent()
        
        if let generator = embeddingGenerator {
            _ = try generator.generateEmbeddings(for: "test")
        }
        
        let duration = CFAbsoluteTimeGetCurrent() - start
        return String(format: "Local processing time: %.2fms", duration * 1000)
    }
}

enum AIError: Error {
    case embeddingFailed
    case generationFailed
} 
