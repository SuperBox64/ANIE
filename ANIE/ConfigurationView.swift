import SwiftUI

struct ConfigProfile: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var apiKey: String
    var baseURL: String
    var model: String
    var temperature: Double
    
    init(id: UUID = UUID(), name: String, apiKey: String, baseURL: String, model: String = "gpt-3.5-turbo", temperature: Double = 0.7) {
        self.id = id
        self.name = name
        self.apiKey = apiKey
        self.baseURL = baseURL
        self.model = model
        self.temperature = temperature
    }
}

class ConfigurationManager: ObservableObject {
    static let shared = ConfigurationManager()
    
    @Published var profiles: [ConfigProfile] = []
    @Published var selectedProfileId: UUID?
    private let profilesKey = "config_profiles"
    private let selectedProfileKey = "selected_profile"
    
    private init() {
        loadProfiles()
    }
    
    private func loadProfiles() {
        print("📂 Loading configuration profiles")
        if let data = UserDefaults.standard.data(forKey: profilesKey),
           let decoded = try? JSONDecoder().decode([ConfigProfile].self, from: data) {
            // Clean base URLs when loading
            profiles = decoded.map { profile in
                var cleanedProfile = profile
                cleanedProfile.baseURL = cleanBaseURL(profile.baseURL)
                return cleanedProfile
            }
            print("   Loaded \(profiles.count) profiles")
            
            // Load selected profile
            if let selectedId = UserDefaults.standard.string(forKey: selectedProfileKey),
               let uuid = UUID(uuidString: selectedId) {
                selectedProfileId = uuid
                print("   Selected profile ID: \(uuid)")
                if let profile = profiles.first(where: { $0.id == uuid }) {
                    print("   Selected profile: \(profile.name)")
                    print("   Base URL: \(profile.baseURL)")
                }
            } else {
                selectedProfileId = profiles.first?.id
                print("   No saved selection, defaulting to first profile")
            }
        } else {
            print("   No saved profiles found")
        }
    }
    
    private func cleanBaseURL(_ url: String) -> String {
        // Remove trailing slashes and whitespace
        return url.trimmingCharacters(in: .whitespacesAndNewlines)
                 .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    }
    
    func saveProfiles() {
        print("💾 Saving configuration profiles")
        // Clean base URLs before saving
        let cleanedProfiles = profiles.map { profile in
            var cleanedProfile = profile
            cleanedProfile.baseURL = cleanBaseURL(profile.baseURL)
            return cleanedProfile
        }
        
        if let encoded = try? JSONEncoder().encode(cleanedProfiles) {
            UserDefaults.standard.set(encoded, forKey: profilesKey)
            print("   Saved \(cleanedProfiles.count) profiles")
        }
        if let selectedId = selectedProfileId {
            UserDefaults.standard.set(selectedId.uuidString, forKey: selectedProfileKey)
            print("   Saved selected profile ID: \(selectedId)")
            if let profile = cleanedProfiles.first(where: { $0.id == selectedId }) {
                print("   Selected profile: \(profile.name)")
                print("   Base URL: \(profile.baseURL)")
            }
        }
        UserDefaults.standard.synchronize()
    }
    
    var selectedProfile: ConfigProfile? {
        get {
            guard let id = selectedProfileId else { return nil }
            return profiles.first { $0.id == id }
        }
        set {
            if let profile = newValue {
                if let index = profiles.firstIndex(where: { $0.id == profile.id }) {
                    profiles[index] = profile
                    saveProfiles()
                }
            }
        }
    }
    
    func addProfile(name: String, apiKey: String, baseURL: String) {
        let cleanedBaseURL = cleanBaseURL(baseURL)
        let newProfile = ConfigProfile(name: name, apiKey: apiKey, baseURL: cleanedBaseURL)
        profiles.append(newProfile)
        selectedProfileId = newProfile.id
        saveProfiles()
        
        // Notify of credential change
        NotificationCenter.default.post(
            name: Notification.Name("CredentialsDidChange"),
            object: nil,
            userInfo: [
                "apiKey": apiKey,
                "baseURL": cleanedBaseURL
            ]
        )
    }
    
    func deleteProfile(_ id: UUID) {
        profiles.removeAll { $0.id == id }
        if selectedProfileId == id {
            selectedProfileId = profiles.first?.id
        }
        saveProfiles()
    }
}

struct ConfigurationView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var configManager = ConfigurationManager.shared
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
    @State private var showingNewProfileSheet = false
    @State private var newProfileName = ""
    
    private func loadExistingCredentials() {
        print("🔍 Loading credentials from profile")
        if let profile = configManager.selectedProfile {
            print("   Selected profile: \(profile.name)")
            
            // Update local state FIRST
            apiKey = profile.apiKey
            baseURL = profile.baseURL  // Set this BEFORE printing
            model = profile.model
            temperature = profile.temperature
            
            print("   Current Base URL: \(baseURL)")  // Now they should match
            print("   Profile Base URL: \(profile.baseURL)")
            
            // Notify of credential change
            NotificationCenter.default.post(
                name: Notification.Name("CredentialsDidChange"),
                object: nil,
                userInfo: [
                    "apiKey": profile.apiKey,
                    "baseURL": profile.baseURL
                ]
            )
            print("✅ Credentials loaded and notification posted")
            print("   Final Base URL: \(baseURL)")
        } else {
            print("❌ No profile selected")
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

        ZStack(alignment: .topTrailing) {
            
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
                .padding()
                .frame(alignment: .trailing)
            }
        }
        

        VStack(spacing: 0) {
            // App Icon and Title
            Image(nsImage: NSImage(named: "AppIcon") ?? NSImage())
                .resizable()
                .frame(width: 100, height: 100)
                .padding(.top, 10)
        
            Text("ANIE Configuration")
                .font(.title)
                .fontWeight(.bold)
                .padding(.bottom, 20)

            // Main content area with light background
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Menu {
                        ForEach(configManager.profiles) { profile in
                            Button(profile.name) {
                                print("🔄 Switching to profile: \(profile.name)")
                                configManager.selectedProfileId = profile.id
                                loadExistingCredentials()  // This will also post the notification
                                print("   New Base URL: \(profile.baseURL)")
                                print("   New Model: \(profile.model)")
                            }
                        }
                        
                        Divider()
                        
                        Button("Add New Profile...") {
                            showingNewProfileSheet = true
                        }
                    } label: {
                        HStack {
                            Text(configManager.selectedProfile?.name ?? "Select Profile")
                                .fontWeight(.medium)
                            Image(systemName: "chevron.down")
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.controlBackgroundColor))
                        )
                    }
                    
                    if let selectedId = configManager.selectedProfileId {
                        Button(role: .destructive) {
                            configManager.deleteProfile(selectedId)
                        } label: {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                        .frame(alignment: .trailing)
                        .buttonStyle(.plain)
                    }
                    
                }
                
                Text("LLM API Configuration")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("API Key")
                        .foregroundColor(.secondary)
                    SecureField("Enter API Key", text: $apiKey)
                        .textFieldStyle(.roundedBorder)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Base URL")
                        .foregroundColor(.secondary)
                    HStack(spacing: 8) {
                        TextField(
                            "e.g., https://api.example.com/v1",
                            text: $baseURL
                        )
                        .textFieldStyle(.roundedBorder)
                        
                        Menu {
                            Button("OpenAI") {
                                baseURL = "https://api.openai.com/v1"
                            }
                            Button("DeepSeek") {
                                baseURL = "https://api.deepseek.com/v1"
                            }
                        } label: {
                            Text("Presets")
                            Image(systemName: "ellipsis.circle")
                                .foregroundColor(.accentColor)
                        }
                        .menuStyle(.borderlessButton)
                        .frame(width:90)
                    }
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
                            
                            try saveCredentials(apiKey: apiKey, baseURL: baseURL)
                            shouldRefresh = true
                            dismiss()
                        } catch {
                            alertMessage = "Error saving credentials: \(error.localizedDescription)"
                            showingAlert = true
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(apiKey.isEmpty)
                    
                    if configManager.selectedProfile != nil {
                        Button("Clear Credentials") {
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
        .sheet(isPresented: $showingNewProfileSheet) {
            NewProfileSheet(isPresented: $showingNewProfileSheet, configManager: configManager)
        }
        .onAppear {
            loadExistingCredentials()
            loadCachedModels()
        }
        .onChange(of: model) { newValue in
            UserDefaults.standard.set(newValue, forKey: "selectedModel")
            // Post specific model change notification
            NotificationCenter.default.post(
                name: Notification.Name("LLMModelDidChange"),
                object: nil,
                userInfo: ["model": newValue]
            )
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
                    .filter { $0.id.hasPrefix("gpt-") || $0.id.hasPrefix("deepseek-chat") }  // Only show GPT and Llama models
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
    
    private func saveCredentials(apiKey: String, baseURL: String) throws {
        if let profile = configManager.selectedProfile {
            print("\n💾 Saving configuration:")
            print("   Profile: \(profile.name)")
            
            // Clean the base URL once
            let cleanBaseURL = baseURL.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                                    .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            print("   Base URL: \(cleanBaseURL)")
            print("   API Key: \(apiKey.prefix(4))...")
            print("   Model: \(model)")
            print("   Temperature: \(temperature)")
            
            // Create updated profile
            let updatedProfile = ConfigProfile(
                id: profile.id,
                name: profile.name,
                apiKey: apiKey,
                baseURL: cleanBaseURL,
                model: model,
                temperature: temperature
            )
            
            // Update profile first
            configManager.selectedProfile = updatedProfile
            
            // Then post a single notification with the cleaned values
            NotificationCenter.default.post(
                name: Notification.Name("CredentialsDidChange"),
                object: nil,
                userInfo: [
                    "apiKey": apiKey,
                    "baseURL": cleanBaseURL
                ]
            )
            print("✅ Configuration saved and notification posted")
        } else {
            print("❌ No profile selected for saving configuration")
            throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "No profile selected"])
        }
    }
}

struct NewProfileSheet: View {
    @Binding var isPresented: Bool
    @ObservedObject var configManager: ConfigurationManager
    @State private var name = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    @FocusState private var isNameFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Text("New Profile")
                .font(.headline)
            
            TextField("Profile Name", text: $name)
                .textFieldStyle(.roundedBorder)
                .focused($isNameFieldFocused)
            
            HStack(spacing: 12) {
                Button("Cancel") {
                    isPresented = false
                }
                .keyboardShortcut(.escape, modifiers: [])
                
                Button("Add") {
                    if name.isEmpty {
                        errorMessage = "Profile name is required"
                        showingError = true
                        return
                    }
                    
                    configManager.addProfile(
                        name: name,
                        apiKey: "",
                        baseURL: ""
                    )
                    isPresented = false
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.return, modifiers: [])
            }
        }
        .padding(20)
        .frame(width: 300, height: 130)
        .background(Color(.windowBackgroundColor))
        .onAppear {
            isNameFieldFocused = true
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
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
