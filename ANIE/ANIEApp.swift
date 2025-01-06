//
//  ANIEApp.swift
//  ANIE
//
//  Created by SuperBox64m on 1/5/25.
//

import SwiftUI
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Set window title after a brief delay to ensure window is created
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let window = NSApp.windows.first {
                window.title = "ANIE: Artificial Neural Intelligence Engine"
                window.titleVisibility = .visible
            }
        }
    }
}

@main
struct ANIEApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var viewModel = LLMViewModel()
    @State private var showingConfiguration = false
    @State private var shouldRefreshCredentials = false
    
    var body: some Scene {
        WindowGroup {
            LLMChatView(viewModel: viewModel)
                .frame(minWidth: 400, minHeight: 300)
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
