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
    
//    private var redactedApiKey: String {
//        if credentialsManager.isConfigured {
//            return "[API Key]"
//        }
//        return ""
//    }
    
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
    
    var body: some View {
        VStack(spacing: 20) {
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
            
            // App Icon and Title
            Image(nsImage: NSImage(named: "AppIcon") ?? NSImage())
                .resizable()
                .frame(width: 100, height: 100)
            
            Text("ANIE Configuration")
                .font(.title)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 20) {
                Text("LLM API Configuration")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("API Key")
                        .foregroundColor(.secondary)
                    if credentialsManager.isConfigured {
                        SecureField("[API Key Redacted]", text: $apiKey)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 400)
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
                            .frame(width: 400)
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
                    .frame(width: 400)
                }
                
                Divider()
                
                Text("Model Configuration")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Model")
                        .foregroundColor(.secondary)
                    TextField("Model name", text: $model)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 400)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Temperature (\(temperature, specifier: "%.1f"))")
                        .foregroundColor(.secondary)
                    Slider(value: $temperature, in: 0...2) {
                        Text("Temperature")
                    }
                    .frame(width: 400)
                }
                
                HStack(spacing: 20) {
                    Button("Cancel") {
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
            
            Spacer()
        }
        .frame(width: 500, height: 600)
        .alert("Configuration Error", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            loadExistingCredentials()
        }
        .onChange(of: model) { newValue in
            UserDefaults.standard.set(newValue, forKey: "selectedModel")
        }
    }
} 
