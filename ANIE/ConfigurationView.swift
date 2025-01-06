import SwiftUI

struct ConfigurationView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var credentialsManager = CredentialsManager()
    @State private var apiKey = ""
    @State private var baseURL = "https://api.openai.com/v1"
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @Binding var shouldRefresh: Bool
    
    private var redactedApiKey: String {
        if credentialsManager.isConfigured {
            return "[API Key Redacted]"
        }
        return ""
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
                Text("OpenAI API Configuration")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("API Key")
                        .foregroundColor(.secondary)
                    SecureField(credentialsManager.isConfigured ? "[API Key Redacted]" : "sk-...", text: $apiKey)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 400)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Base URL")
                        .foregroundColor(.secondary)
                    TextField("Base URL", text: $baseURL)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 400)
                }
                
                HStack(spacing: 20) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .keyboardShortcut(.escape, modifiers: [])
                    
                    Button("Save Configuration") {
                        do {
                            try credentialsManager.saveCredentials(apiKey: apiKey, baseURL: baseURL)
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
                            baseURL = "https://api.openai.com/v1"
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
    }
} 