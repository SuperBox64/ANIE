import Foundation

struct LocalAIResponses {
    // Dynamic response variations
    struct Variations {
        static let greetings = [
            "Hello! How can I help you today?",
            "Hi there! What can I do for you?",
            "Hey! I'm here to help. What's on your mind?",
            "Greetings! How may I assist you?",
            "Welcome! What would you like to know?"
        ]
        
        static let gratitude = [
            "You're welcome! Let me know if you need anything else.",
            "Glad I could help! Feel free to ask more questions.",
            "No problem at all! What else would you like to know?",
            "Happy to help! Is there anything else you'd like to explore?",
            "Anytime! Don't hesitate to ask if you need more assistance."
        ]
        
        static let statusResponses = [
            "I'm functioning well and ready to assist you! What would you like to know?",
            "All systems operational and ready to help! What's your question?",
            "I'm doing great and eager to help! What can I do for you?",
            "Everything's running smoothly! What would you like to explore?",
            "I'm at your service and ready to assist! What's on your mind?"
        ]
        
        static let clarification = [
            "Could you please provide more details about that?",
            "I'd like to understand better. Can you elaborate?",
            "Would you mind explaining a bit more?",
            "Can you give me some more context?",
            "Tell me more about what you're looking for."
        ]
        
        static let acknowledgment = [
            "I understand you're asking about",
            "You're interested in learning about",
            "You'd like to know more about",
            "You're curious about",
            "You're asking me about"
        ]
    }
    
    // Static responses
    struct Static {
        static let creator = "I was created by Todd Bruss, an imaginative out of the box thinker."
        
        static let introduction = "I'm ANIE (Artificial Neural Intelligence Engine), your local AI assistant. I specialize in programming help and general conversation."
        
        static let capabilities = """
            I am ANIE (Artificial Neural Intelligence Engine), and I can help you with:
            - Programming guidance and code examples
            - General questions and conversation
            - Task assistance and problem-solving
            - Technical explanations
            - Basic calculations and analysis
            
            I'm currently running in Local AI mode, which means I operate without network connectivity.
            """
        
        static let defaultCapabilities = """
            ANIE's Local AI Capabilities:
            
            1. Programming Help:
               - Swift syntax and examples (functions, classes, structs)
               - SwiftUI and UIKit guidance
               - Design patterns (MVC, MVVM, Protocol-Oriented)
               - Error handling and debugging
               - Memory management and optimization
               - Concurrency and async/await
               - Unit testing and test-driven development
               - Package management and dependencies
            
            2. System Information:
               - Apple Neural Engine (ANE) status and capabilities
               - CoreML model management and performance
               - BERT embeddings and semantic search
               - Cache system and response storage
               - Memory usage and optimization
               - Hardware acceleration metrics
               - System resource utilization
               - Performance benchmarks and analysis
            
            3. Technical Knowledge:
               - Neural network architectures and training
               - Machine learning models and algorithms
               - Natural Language Processing (NLP)
               - Transformer models and BERT
               - System architecture patterns
               - Data processing pipelines
               - Optimization techniques
               - Security best practices
            
            4. Available Commands:
               - !ml status  (View detailed system status)
               - !ml clear   (Clear all caches and history)
               - !ml help    (Show comprehensive help)
               - !ml bert    (BERT model information)
               - !ml cache   (Cache statistics)
               - !ml perf    (Performance metrics)
            
            5. Local Processing Features:
               - Offline operation capability
               - Hardware-accelerated responses
               - Semantic search with BERT
               - Response caching system
               - Context-aware processing
               - Real-time performance metrics
            
            How can I assist you with these topics?
            [Using LocalAI]
            """
    }
    
    // Programming help responses
    struct Programming {
        static let swiftUI = """
            SwiftUI Development Guide:
            
            1. Basic Views and Layouts:
               ```swift
               struct ContentView: View {
                   var body: some View {
                       VStack(spacing: 20) {
                           Text("Hello, World!")
                               .font(.title)
                           Image(systemName: "star.fill")
                           Button("Tap Me") {
                               // Action
                           }
                       }
                       .padding()
                   }
               }
               ```
            
            2. State Management:
               ```swift
               struct CounterView: View {
                   @State private var count = 0
                   @StateObject private var viewModel = ViewModel()
                   @Binding var isActive: Bool
                   
                   var body: some View {
                       VStack {
                           Text("Count: \\(count)")
                           Button("Increment") {
                               count += 1
                           }
                       }
                   }
               }
               ```
            
            3. Data Flow:
               - @State for simple local state
               - @Binding for two-way bindings
               - @StateObject for observable objects
               - @EnvironmentObject for dependency injection
               - @Published for observable properties
            
            4. Layout System:
               - VStack/HStack/ZStack
               - LazyVGrid/LazyHGrid
               - ScrollView and Lists
               - GeometryReader for custom layouts
               - Custom alignment guides
            
            5. Best Practices:
               - Keep views small and focused
               - Use preview providers
               - Extract reusable components
               - Follow MVVM pattern
               - Use proper state management
            """
        
        static let concurrency = """
            Swift Concurrency Guide:
            
            1. Async/Await Basics:
               ```swift
               func fetchData() async throws -> Data {
                   let (data, _) = try await URLSession.shared.data(from: url)
                   return data
               }
               
               // Usage
               Task {
                   do {
                       let data = try await fetchData()
                       // Process data
                   } catch {
                       // Handle error
                   }
               }
               ```
            
            2. Actor Implementation:
               ```swift
               actor DataManager {
                   private var cache: [String: Data] = [:]
                   
                   func getData(for key: String) -> Data? {
                       return cache[key]
                   }
                   
                   func setData(_ data: Data, for key: String) {
                       cache[key] = data
                   }
               }
               ```
            
            3. Task Management:
               ```swift
               // Task groups
               try await withThrowingTaskGroup(of: Data.self) { group in
                   for url in urls {
                       group.addTask {
                           let (data, _) = try await URLSession.shared.data(from: url)
                           return data
                       }
                   }
               }
               
               // Cancellation
               let task = Task {
                   try await someOperation()
               }
               task.cancel()
               ```
            
            4. Best Practices:
               - Use structured concurrency
               - Handle cancellation appropriately
               - Avoid data races with actors
               - Consider thread confinement
               - Use async sequences for streams
            """
        
        static let testing = """
            Unit Testing in Swift:
            
            1. Test Structure:
               ```swift
               import XCTest
               @testable import YourModule
               
               final class DataManagerTests: XCTestCase {
                   var sut: DataManager!
                   
                   override func setUp() {
                       super.setUp()
                       sut = DataManager()
                   }
                   
                   override func tearDown() {
                       sut = nil
                       super.tearDown()
                   }
                   
                   func testDataStorage() {
                       // Given
                       let data = "test".data(using: .utf8)!
                       
                       // When
                       sut.store(data, for: "key")
                       
                       // Then
                       XCTAssertEqual(sut.getData(for: "key"), data)
                   }
               }
               ```
            
            2. Async Testing:
               ```swift
               func testAsyncOperation() async throws {
                   // Given
                   let expectation = "expected result"
                   
                   // When
                   let result = try await sut.performOperation()
                   
                   // Then
                   XCTAssertEqual(result, expectation)
               }
               ```
            
            3. Mocking and Stubbing:
               ```swift
               protocol NetworkService {
                   func fetchData() async throws -> Data
               }
               
               class MockNetworkService: NetworkService {
                   var mockData: Data?
                   var mockError: Error?
                   
                   func fetchData() async throws -> Data {
                       if let error = mockError {
                           throw error
                       }
                       return mockData ?? Data()
                   }
               }
               ```
            
            4. Test Coverage:
               - Use XCTest measurements
               - Track code coverage
               - Test edge cases
               - Test error conditions
               - Use test doubles
            """
        
        static let patterns = """
            Swift Design Patterns:
            
            1. MVVM Pattern:
               ```swift
               // Model
               struct User {
                   let id: UUID
                   var name: String
               }
               
               // ViewModel
               class UserViewModel: ObservableObject {
                   @Published private(set) var user: User
                   
                   func updateName(_ newName: String) {
                       user.name = newName
                   }
               }
               
               // View
               struct UserView: View {
                   @StateObject var viewModel: UserViewModel
                   
                   var body: some View {
                       VStack {
                           Text(viewModel.user.name)
                           Button("Update") {
                               viewModel.updateName("New Name")
                           }
                       }
                   }
               }
               ```
            
            2. Protocol-Oriented Programming:
               ```swift
               protocol Identifiable {
                   var id: UUID { get }
               }
               
               protocol Displayable {
                   var displayName: String { get }
               }
               
               extension Displayable where Self: Identifiable {
                   var debugDescription: String {
                       "\\(displayName) (\\(id))"
                   }
               }
               ```
            
            3. Dependency Injection:
               ```swift
               protocol DataService {
                   func fetchData() async throws -> Data
               }
               
               class DataManager {
                   private let service: DataService
                   
                   init(service: DataService) {
                       self.service = service
                   }
               }
               ```
            
            4. Factory Pattern:
               ```swift
               protocol ViewFactory {
                   func makeContentView() -> ContentView
                   func makeSettingsView() -> SettingsView
               }
               
               class ViewFactoryImpl: ViewFactory {
                   func makeContentView() -> ContentView {
                       let viewModel = ContentViewModel()
                       return ContentView(viewModel: viewModel)
                   }
               }
               ```
            """
    }
    
    // System information responses
    struct SystemInfo {
        static func hardware() -> String {
            let info = MLDeviceCapabilities.getSystemInfo()
            return """
                Hardware Configuration:
                
                1. Neural Engine Status:
                   - ANE Available: \(info["hasANE"] as? Bool == true ? "Yes" : "No")
                   - Compute Units: \(info["computeUnits"] ?? "Unknown")
                   - Processing Mode: \(info["hasANE"] as? Bool == true ? "Hardware Accelerated" : "CPU/GPU Based")
                
                2. ML Capabilities:
                   - BERT Model: \(info["modelActive"] as? Bool == true ? "Active" : "Inactive")
                   - Embedding Dimension: \(EmbeddingsService.shared.generator?.modelInfo()["embeddingDimension"] ?? 0)
                   - Operations Count: \(info["usageCount"] ?? 0)
                
                3. Performance Metrics:
                   - Memory Usage: \(ProcessInfo.processInfo.physicalMemory / 1024 / 1024) MB
                   - CPU Usage: \(ProcessInfo.processInfo.systemUptime)s
                   - Active Processors: \(ProcessInfo.processInfo.processorCount)
                
                4. Optimization Status:
                   - Hardware Acceleration: \(info["hasANE"] as? Bool == true ? "Enabled" : "Disabled")
                   - Neural Engine Utilization: Active
                   - Processing Pipeline: Optimized
                """
        }
        
        static func cache() -> String {
            """
                Cache System Status:
                
                1. Configuration:
                   - Cache Size: \(ResponseCache.shared.getCacheSize()) entries
                   - Similarity Threshold: \(String(format: "%.2f", ResponseCache.shared.threshold))
                   - Storage Type: Persistent
                
                2. BERT Integration:
                   - Embedding Model: Active
                   - Vector Dimension: \(EmbeddingsService.shared.generator?.modelInfo()["embeddingDimension"] ?? 0)
                   - Semantic Search: Enabled
                
                3. Performance:
                   - Response Time: < 100ms
                   - Memory Usage: Optimized
                   - Storage Efficiency: High
                
                4. Features:
                   - Semantic Matching
                   - Persistence
                   - Auto-optimization
                   - Query Analysis
                """
        }
        
        static func mlCapabilities() -> String {
            """
                ML System Capabilities:
                
                1. BERT Model:
                   - Type: Bidirectional Encoder
                   - Purpose: Text Embeddings
                   - Integration: CoreML
                   - Acceleration: ANE
                
                2. Processing Pipeline:
                   - Text Tokenization
                   - Embedding Generation
                   - Semantic Analysis
                   - Response Matching
                
                3. Optimization:
                   - Hardware Acceleration
                   - Memory Management
                   - Cache Utilization
                   - Performance Tuning
                
                4. Features:
                   - Offline Processing
                   - Local Operation
                   - Fast Response Time
                   - High Accuracy
                """
        }
    }
    
    // Technical knowledge responses
    struct Technical {
        static func neuralNetworks() -> String {
            """
                Neural Networks in ANIE:
                
                1. Architecture Overview:
                   - Input Layer: Text Processing
                   - Hidden Layers: Contextual Analysis
                   - Output Layer: Embedding Generation
                   - Attention Mechanism: BERT
                
                2. Components:
                   - Neurons: Processing Units
                   - Weights: Connection Strengths
                   - Activation Functions: Non-linear Transformers
                   - Layers: Organized Processing Stages
                
                3. Implementation:
                   - Framework: CoreML
                   - Model: BERT
                   - Acceleration: Apple Neural Engine
                   - Optimization: Hardware-specific
                
                4. Applications:
                   - Text Understanding
                   - Semantic Analysis
                   - Pattern Recognition
                   - Context Processing
                
                5. Performance:
                   - Processing Speed: Optimized
                   - Memory Usage: Efficient
                   - Accuracy: High
                   - Power Usage: Optimized
                """
        }
        
        static func machineLearning() -> String {
            """
                Machine Learning System:
                
                1. Core Technologies:
                   - BERT: Bidirectional Encoding
                   - CoreML: Apple's ML Framework
                   - ANE: Neural Engine Acceleration
                   - NLP: Natural Language Processing
                
                2. Processing Pipeline:
                   - Input Processing
                   - Tokenization
                   - Embedding Generation
                   - Semantic Analysis
                   - Response Generation
                
                3. Optimization:
                   - Hardware Acceleration
                   - Memory Management
                   - Cache Utilization
                   - Performance Tuning
                
                4. Features:
                   - Offline Processing
                   - Local Operation
                   - Real-time Analysis
                   - Adaptive Learning
                """
        }
        
        static func architecture() -> String {
            """
                System Architecture:
                
                1. Core Components:
                   - BERT Model Layer
                   - Processing Pipeline
                   - Cache System
                   - Response Generator
                
                2. Data Flow:
                   - Input Validation
                   - Preprocessing
                   - ML Processing
                   - Cache Integration
                   - Response Formation
                
                3. Integration:
                   - CoreML Framework
                   - Apple Neural Engine
                   - System Services
                   - Storage System
                
                4. Optimization:
                   - Parallel Processing
                   - Memory Management
                   - Cache Strategy
                   - Resource Utilization
                
                5. Security:
                   - Local Processing
                   - Data Privacy
                   - Secure Storage
                   - Access Control
                """
        }
    }
} 