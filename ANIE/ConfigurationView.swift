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
        if let models = try? JSONDecoder().decode([String].self, from: cachedModelsData) {
            availableModels = models
            print("📚 Loaded \(models.count) cached models")
        }
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
                    Text("Model")
                        .foregroundColor(.secondary)
                    
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
                        .disabled(availableModels.isEmpty)
                        .popover(isPresented: $showingModelSelector, arrowEdge: .top) {
                            VStack(alignment: .leading) {
                                Text("Available Models")
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
                                    List(availableModels, id: \.self) { modelName in
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
                                    .frame(width: 300, height: 500)  // Made significantly taller
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
        .frame(width: 580, height: 700)  // Increased size to accommodate padding
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
                availableModels = response.data
                    .filter { $0.id.hasPrefix("gpt-") }  // Only show GPT models
                    .map { $0.id }
                    .sorted()
                
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
