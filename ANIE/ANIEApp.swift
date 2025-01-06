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
        NSApp.windows.first?.title = "ANIE: Artificial Neural Intelligence Engine"
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
