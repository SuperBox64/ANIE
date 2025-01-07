//
//  ANIEApp.swift
//  ANIE
//
//  Created by SuperBox64m on 1/5/25.
//

import SwiftUI
import AppKit

// Add a global singleton for embeddings
class EmbeddingsService {
    static let shared = EmbeddingsService()
    private(set) var generator: EmbeddingsGenerator?
    private(set) var usageCount: Int = 0
    
    private init() {
        do {
            generator = try EmbeddingsGenerator()
            // Print initial diagnostics
            if let info = generator?.modelInfo() {
                print("=== Embeddings Model Initialized ===")
                print("BERT Model Status: Active")
                print("Compute Unit: \(MLDeviceCapabilities.hasANE ? "Apple Neural Engine" : "CPU/GPU")")
                print("Model Info:", info)
                print("==================================")
            }
        } catch {
            print("⚠️ Failed to initialize BERT embeddings: \(error.localizedDescription)")
        }
    }
    
    func logUsage(operation: String) {
        usageCount += 1
        print("🤖 BERT Usage [\(usageCount)] - \(operation)")
    }
    
    func getStats() -> String {
        """
        === BERT Usage Statistics ===
        Total Operations: \(usageCount)
        ANE Available: \(MLDeviceCapabilities.hasANE)
        Active: \(generator != nil)
        ========================
        """
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize embeddings service
        _ = EmbeddingsService.shared
        
        // Set window title after a brief delay to ensure window is created
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let window = NSApp.windows.first {
                window.title = "ANIE: Artificial Neural Intelligence Engine"
                window.titleVisibility = .visible
            }
        }
    }
}

// Add this class to manage scroll state
class ScrollManager: ObservableObject {
    static let shared = ScrollManager()
    @Published var shouldScrollToBottom = false
    
    func scrollToBottom() {
        shouldScrollToBottom = true
        // Reset after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.shouldScrollToBottom = false
        }
    }
}

@main
struct ANIEApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var viewModel = LLMViewModel()
    @StateObject private var scrollManager = ScrollManager.shared
    @State private var showingConfiguration = false
    @State private var shouldRefreshCredentials = false
    
    var body: some Scene {
        WindowGroup {
            LLMChatView(viewModel: viewModel)
                .frame(minWidth: 400, minHeight: 300)
                .environmentObject(scrollManager)  // Inject scroll manager
                .onAppear {
                    if !viewModel.hasValidCredentials {
                        showingConfiguration = true
                    }
                }
                .sheet(isPresented: $showingConfiguration) {
                    ConfigurationView(shouldRefresh: $shouldRefreshCredentials)
                }
                .onChange(of: shouldRefreshCredentials) { oldValue, newValue in
                    if newValue {
                        viewModel.refreshCredentials()
                        shouldRefreshCredentials = false
                    }
                }
        }
        .windowStyle(.automatic)
        .defaultSize(width: 800, height: 600)
    }
}
