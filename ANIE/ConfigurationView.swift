import SwiftUI

struct ConfigurationView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var credentialsManager = CredentialsManager()
    @State private var apiKey = ""
    @State private var baseURL = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @Binding var shouldRefresh: Bool
    @AppStorage("useLocalAI") private var useLocalAI = false
    @AppStorage("llm-model") private var model = "gpt-3.5-turbo"
    @AppStorage("llm-temperature") private var temperature = 0.7
    @AppStorage("cached-models") private var cachedModelsData: Data = Data()
    @State private var availableModels: [String] = []
    @State private var isLoadingModels = false
    @State private var showingModelSelector = false
    @State private var modelType: ModelType = .gpt
    
    private enum ModelType {
        case gpt
        case reasoning
    }
    
    private var filteredModels: [String] {
        switch modelType {
        case .gpt:
            return availableModels.filter { $0.hasPrefix("gpt") }
        case .reasoning:
            return availableModels.filter { modelId in
                // Match Claude models (o1-) and o3 models
                modelId.hasPrefix("o1-") || modelId.hasPrefix("o3-")
            }.sorted { a, b in
                // Custom sorting:
                // 1. Claude base models first
                // 2. Claude mini models second
                // 3. Claude preview models third
                // 4. o3 models fourth
                // 5. Dated versions within each category sorted in reverse chronological order
                
                // Helper function to get model priority
                func getPriority(_ model: String) -> Int {
                    if model.hasPrefix("o1-mini") { return 1 }  // Claude mini models
                    if model.hasPrefix("o1-preview") { return 2 }  // Claude preview models
                    if model.hasPrefix("o3-") { return 3 }  // o3 models
                    if model.hasPrefix("o1-") { return 0 }  // Other Claude models
                    return 4  // Others
                }
                
                let aPriority = getPriority(a)
                let bPriority = getPriority(b)
                
                if aPriority != bPriority {
                    return aPriority < bPriority
                }
                
                // If same priority and contains date, sort in reverse chronological order
                if a.contains("-202") && b.contains("-202") {
                    return a > b
                }
                
                // Otherwise sort alphabetically
                return a < b
            }
        }
    }
    
    private func loadExistingCredentials() {
        if let credentials = credentialsManager.getCredentials() {
            if baseURL.isEmpty {
                baseURL = credentials.baseURL
            }
            if apiKey.isEmpty {
                apiKey = credentialsManager.isConfigured ? credentials.apiKey : ""
            }
        }
    }
    
    private func loadCachedModels() {
        var models: [String] = []
        
        // Load cached models
        if let cachedModels = try? JSONDecoder().decode([String].self, from: cachedModelsData) {
            models = cachedModels
            print("📚 Loaded \(models.count) cached models")
        }
        
        // Add o3 models manually
        let o3Models = [
            "o3-mini",
            "o3-mini-2025-01-31"
        ]
        
        // Add any missing o3 models
        for model in o3Models {
            if !models.contains(model) {
                models.append(model)
            }
        }
        
        availableModels = models.sorted()
        print("📚 Total models (including manual additions): \(availableModels.count)")
    }
    
    private func saveCachedModels() {
        if let data = try? JSONEncoder().encode(availableModels) {
            cachedModelsData = data
            print("💾 Cached \(availableModels.count) models")
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Close button in top-right corner
            HStack {
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.gray)
                }
                .buttonStyle(.plain)
                .padding([.top, .trailing], 20)
            }
            .padding(.bottom, 10)
            
            // App Icon and Title
            Image(nsImage: NSImage(named: "AppIcon") ?? NSImage())
                .resizable()
                .frame(width: 100, height: 100)
                .padding(.bottom, 10)
            
            Text("ANIE Configuration")
                .font(.title)
                .fontWeight(.bold)
                .padding(.bottom, 20)
            
            // Main content area with light background
            VStack(alignment: .leading, spacing: 20) {
                Text("LLM API Configuration")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("API Key")
                        .foregroundColor(.secondary)
                    if credentialsManager.isConfigured {
                        SecureField("[API Key Redacted]", text: $apiKey)
                            .textFieldStyle(.roundedBorder)
                            .onChange(of: apiKey) { newValue in
                                // Only update if user starts typing
                                if !newValue.isEmpty && newValue != "[API Key Redacted]" {
                                    // Clear the placeholder text when user starts typing
                                    if apiKey == "[API Key Redacted]" {
                                        apiKey = ""
                                    }
                                }
                            }
                    } else {
                        SecureField("Enter API Key", text: $apiKey)
                            .textFieldStyle(.roundedBorder)
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Base URL")
                        .foregroundColor(.secondary)
                    TextField(
                        "e.g., https://api.example.com/v1",
                        text: $baseURL
                    )
                    .textFieldStyle(.roundedBorder)
                }
                
                Divider()
                
                Text("Model Configuration")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Model Type")
                        .foregroundColor(.secondary)
                    
                    Picker("Model Type", selection: $modelType) {
                        Text("GPT").tag(ModelType.gpt)
                        Text("Reasoning").tag(ModelType.reasoning)
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: modelType) { _ in
                        // Reset selected model when switching types
                        if !filteredModels.contains(model) {
                            model = filteredModels.first ?? ""
                        }
                    }
                    
                    Text("Model")
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                    
                    HStack(spacing: 8) {
                        TextField("Model name", text: $model)
                            .textFieldStyle(.roundedBorder)
                        
                        Button {
                            showingModelSelector = true
                        } label: {
                            Image(systemName: "chevron.down.circle.fill")
                                .foregroundColor(.accentColor)
                        }
                        .buttonStyle(.plain)
                        .disabled(filteredModels.isEmpty)
                        .popover(isPresented: $showingModelSelector, arrowEdge: .top) {
                            VStack(alignment: .leading) {
                                Text(modelType == .gpt ? "GPT Models" : "Reasoning Models")
                                    .font(.headline)
                                    .padding(.leading, 16)
                                    .padding(.top, 8)

                                if isLoadingModels {
                                    HStack {
                                        ProgressView()
                                            .scaleEffect(0.5)
                                        Text("Loading models...")
                                    }
                                } else {
                                    List(filteredModels, id: \.self) { modelName in
                                        Button {
                                            model = modelName
                                            showingModelSelector = false
                                            shouldRefresh = true
                                        } label: {
                                            HStack {
                                                Text(modelName)
                                                if model == modelName {
                                                    Spacer()
                                                    Image(systemName: "checkmark")
                                                        .foregroundColor(.accentColor)
                                                }
                                            }
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    .frame(width: 300, height: 300)
                                }
                            }
                        }
                        
                        Button("Refresh") {
                            Task {
                                await refreshAvailableModels()
                            }
                        }
                        .disabled(isLoadingModels || apiKey.isEmpty || baseURL.isEmpty)
                    }
                }
                
                VStack(alignment: .leading) {
                    Text("Temperature")
                        .foregroundColor(.secondary)
                    
                    HStack() {
                        Text("\(temperature, specifier: "%.1f")")
                            .foregroundColor(.secondary)
                            .font(.system(size: 12))
                            .frame(alignment: .leading)
                        
                        Slider(value: $temperature, in: 0...2)
                    }
                }
                
                HStack(spacing: 32) {
                    Button("Close Window") {
                        dismiss()
                    }
                    .keyboardShortcut(.escape, modifiers: [])
                    
                    Button("Save Configuration") {
                        do {
                            guard !baseURL.isEmpty else {
                                alertMessage = "Base URL cannot be empty"
                                showingAlert = true
                                return
                            }
                            
                            let cleanBaseURL = baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
                            
                            try credentialsManager.saveCredentials(apiKey: apiKey, baseURL: cleanBaseURL)
                            shouldRefresh = true
                            dismiss()
                        } catch {
                            alertMessage = "Error saving credentials: \(error.localizedDescription)"
                            showingAlert = true
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(apiKey.isEmpty)
                    
                    if credentialsManager.isConfigured {
                        Button("Clear Credentials") {
                            credentialsManager.clearCredentials()
                            apiKey = ""
                            baseURL = ""
                            dismiss()
                        }
                        .foregroundColor(.red)
                    }
                }
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.windowBackgroundColor))
                    .shadow(radius: 2)
            )
            .padding(.horizontal, 40)  // Add horizontal padding
            .padding(.bottom, 40)      // Add bottom padding
        }
        .frame(width: 580, height: .infinity)  // Increased size to accommodate padding
        .background(Color(.windowBackgroundColor).opacity(0.2))  // Slightly darker background for contrast
        .alert("Configuration Error", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            loadExistingCredentials()
            loadCachedModels()
        }
        .onChange(of: model) { newValue in
            UserDefaults.standard.set(newValue, forKey: "selectedModel")
        }
    }
    
    private func refreshAvailableModels() async {
        isLoadingModels = true
        defer { isLoadingModels = false }
        
        do {
            let cleanBaseURL = baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            let modelsURL = URL(string: "\(cleanBaseURL)/models")!
            
            var request = URLRequest(url: modelsURL)
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(ModelsResponse.self, from: data)
            
            await MainActor.run {
                var models = response.data.map { $0.id }
                
                // Add o3 models manually - preserve them even after refresh
                let o3Models = [
                    "o3-mini",
                    "o3-mini-2025-01-31"
                ]
                
                // Add any missing o3 models
                for model in o3Models {
                    if !models.contains(model) {
                        models.append(model)
                    }
                }
                
                // Store all models
                availableModels = models.sorted()
                
                // Print available models for debugging
                print("📝 Available models:")
                for model in availableModels {
                    print("   • \(model)")
                }
                
                // If current model is not in filtered list, select first available
                if !filteredModels.contains(model) {
                    model = filteredModels.first ?? ""
                }
                
                // Cache the fetched models
                saveCachedModels()
            }
        } catch {
            await MainActor.run {
                alertMessage = "Failed to fetch models: \(error.localizedDescription)"
                showingAlert = true
            }
        }
    }
}

// Add model response types
struct ModelInfo: Codable {
    let id: String
}

struct ModelsResponse: Codable {
    let data: [ModelInfo]
}
