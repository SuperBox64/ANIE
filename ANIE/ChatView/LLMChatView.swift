import SwiftUI
import AppKit

private struct ViewHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct LLMChatView: View {
    @ObservedObject var viewModel: LLMViewModel
    @EnvironmentObject var scrollManager: ScrollManager
    @State private var userInput: String = ""
    @State private var isHovering = false
    @State private var scrollProxy: ScrollViewProxy?
    @State private var lastMessageId: UUID? = nil
    @State private var showingDeleteAlert = false
    @State private var showingConfiguration = false
    @State private var shouldRefreshCredentials = false
    @State private var initialScrollDone = false
    @AppStorage("useLocalAI") private var useLocalAI = false
    @FocusState private var isTextFieldFocused: Bool
    @State private var showingClearDialog = false
    @State private var currentSearchIndex: Int = 0
    @State private var selectedMessageId: UUID? = nil
    @Environment(\.colorScheme) private var colorScheme
    
    private func scrollToMessage(_ messageId: UUID) {
        selectedMessageId = messageId
        if let proxy = scrollProxy {
            withAnimation {
                proxy.scrollTo(messageId, anchor: .center)
            }
        }
    }
    
    var body: some View {
        HSplitView {
            ChatSidebarView(viewModel: viewModel)
            
            VStack(spacing: 32) {
                // Top toolbar
                HStack {
                    // Search bar
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                            .padding(.leading, 16)
                            .padding(.trailing, 2)
                            .padding(.vertical, 8)
                        Text(viewModel.activeSearchTerm.isEmpty ? "0 of 0" : "\(currentSearchIndex + 1) of \(viewModel.filteredMessages?.count ?? 0)")
                            .foregroundColor(.secondary)
                            .font(.system(size: 11))
                            .frame(width: 50)
                        
                        Button(action: {
                            if let messages = viewModel.filteredMessages, !messages.isEmpty {
                                if currentSearchIndex > 0 {
                                    currentSearchIndex -= 1
                                    withAnimation {
                                        scrollProxy?.scrollTo(messages[currentSearchIndex].id, anchor: .top)
                                    }
                                }
                            }
                        }) {
                            Image(systemName: "chevron.up")
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                        .help("Previous match (⇧⌘G)")
                        .keyboardShortcut("g", modifiers: [.command, .shift])
                        .disabled(viewModel.activeSearchTerm.isEmpty || viewModel.filteredMessages?.isEmpty ?? true || currentSearchIndex == 0)
                        .opacity(viewModel.activeSearchTerm.isEmpty ? 0.5 : 1.0)
                        
                        Button(action: {
                            if let messages = viewModel.filteredMessages, !messages.isEmpty {
                                if currentSearchIndex < messages.count - 1 {
                                    currentSearchIndex += 1
                                    withAnimation {
                                        scrollProxy?.scrollTo(messages[currentSearchIndex].id, anchor: .top)
                                    }
                                }
                            }
                        }) {
                            Image(systemName: "chevron.down")
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                        .help("Next match (⌘G)")
                        .keyboardShortcut("g", modifiers: .command)
                        .disabled(viewModel.activeSearchTerm.isEmpty || viewModel.filteredMessages?.isEmpty ?? true || (viewModel.filteredMessages.map { currentSearchIndex >= $0.count - 1 } ?? true))
                        .opacity(viewModel.activeSearchTerm.isEmpty ? 0.5 : 1.0)
                        
                        Button(action: {
                            viewModel.searchTerm = ""
                            viewModel.activeSearchTerm = ""
                            currentSearchIndex = 0
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(colorScheme == .dark ? .black : .white)
                                .background(Circle().fill(colorScheme == .dark ? Color.white : Color.black))
                        }
                        .buttonStyle(.plain)
                        .opacity(viewModel.searchTerm.isEmpty ? 0.5 : 1.0)
                        
                        
                        TextField("Search messages...", text: $viewModel.searchTerm)
                            .textFieldStyle(PlainTextFieldStyle())
                            .frame(maxWidth: .infinity)
                            .padding(.trailing, 16)
                            .onChange(of: viewModel.searchTerm) { newValue in
                                // Only reset index if we're not actively searching
                                if viewModel.activeSearchTerm.isEmpty {
                                    currentSearchIndex = 0
                                }
                            }
                            .onSubmit {
                                // Update active search term and trigger search
                                viewModel.activeSearchTerm = viewModel.searchTerm.trimmingCharacters(in: .whitespacesAndNewlines)
                                currentSearchIndex = 0
                                
                                // Ensure we scroll to the first match
                                if let messages = viewModel.filteredMessages, !messages.isEmpty {
                                    // Give SwiftUI time to update the view
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                        withAnimation {
                                            scrollProxy?.scrollTo("top", anchor: .top)
                                            scrollProxy?.scrollTo(messages[0].id, anchor: .top)
                                        }
                                    }
                                }
                            }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(colorScheme == .dark ? Color.black : Color(nsColor: NSColor.windowBackgroundColor))
                            .shadow(color: Color(.separatorColor).opacity(0.5), radius: 2)
                    )
                    .padding(.vertical, 8)

                    Button {
                        showingConfiguration = true
                    } label: {
                        Image(systemName: "gear")
                            .font(.system(size: 16))
                            .foregroundColor(.primary)
                            .frame(width: 30, height: 30)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color(.controlBackgroundColor))
                            )
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                .padding([.horizontal], 8)
                
                // Messages ScrollView
                ScrollViewReader { proxy in
                    ScrollView {

                        Color.clear
                            .frame(height: 1)
                            .id("top")

                        LazyVStack(spacing: 0) {
                            if let session = viewModel.currentSession {
                                ForEach(Array(session.messages.enumerated()), id: \.element.id) { index, message in
                                    // Add divider above each user message (except the first one)
                                    if message.isUser && index > 0 {
                                        Divider()
                                            .opacity(0.5)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical)
                                        
                                    }
                                    
                                    MessageView(
                                        message: message, 
                                        searchTerm: viewModel.activeSearchTerm,
                                        isCurrentSearchResult: viewModel.filteredMessages?.indices.contains(currentSearchIndex) == true && 
                                            viewModel.filteredMessages?[currentSearchIndex].id == message.id,
                                        isOmitted: Binding(
                                            get: { message.isOmitted },
                                            set: { newValue in
                                                // When toggling a user message, also toggle the corresponding AI response
                                                if message.isUser && index + 1 < session.messages.count {
                                                    viewModel.toggleMessagePairOmitted(
                                                        userMessageId: message.id,
                                                        aiMessageId: session.messages[index + 1].id,
                                                    isOmitted: newValue  // The value is already correct here
                                                    )
                                                }
                                            }
                                        ),
                                        showCheckbox: message.isUser // Only show checkbox for user messages
                                    )
                                    .id(message.id)
                                }
                            }
                        }
                        .padding(.horizontal, 18)
                        .onAppear {
                            withAnimation {
                                proxy.scrollTo("bottom", anchor: .bottom)
                            }
                        }
                        
                        Color.clear
                            .frame(height: 1)
                            .id("bottom")
                    }
                    .onChange(of: viewModel.currentSession?.messages.count) { _ in
                        withAnimation {
                            proxy.scrollTo("bottom", anchor: .bottom)
                        }
                    }
                    .onChange(of: viewModel.selectedSessionId) { _ in
                        withAnimation {
                            proxy.scrollTo("bottom", anchor: .bottom)
                        }
                    }
                    .onAppear {
                        scrollProxy = proxy
                    }
                }
                
                // Bottom input area
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text("Enter some text (⌘↩ to send)")
                            .foregroundColor(.accentColor)
                            .font(.system(size: 12))
                            .padding(.leading, 22)
                    
                        if viewModel.isProcessing {
                            Spacer()
                            ProgressView(value: viewModel.processingProgress, total: 1.0)
                                .progressViewStyle(.linear)
                                .frame(width: 100)
                                .padding(.trailing, 60)
                        }
                    }
                    
                    HStack(alignment: .top, spacing: 22) {
                        TextEditor(text: $userInput)
                            .frame(height: 160)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 14))
                            .padding()
                        
                        VStack(spacing: 22) {
                            Button(action: sendMessage) {
                                Image(systemName: "arrow.up.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(userInput.isEmpty || viewModel.isProcessing ? 
                                        Color.black.opacity(0.5) : .accentColor)
                                    .background(Circle().fill(Color.white))
                                    .contentShape(Circle())
                            }
                            .buttonStyle(PlainButtonStyle())
                            .keyboardShortcut(.return, modifiers: .command)
                            .disabled(userInput.isEmpty || viewModel.isProcessing)

                            Button(action: {
                                showingClearDialog = true
                            }) {
                                Image(systemName: "arrow.uturn.backward.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(.white)
                                    .background(Circle().fill(Color.red))
                                    .contentShape(Circle())
                            }
                            .buttonStyle(PlainButtonStyle())
                            .keyboardShortcut(.delete, modifiers: .command)
                            .disabled(viewModel.currentSession?.messages.isEmpty ?? true)
                            .popover(isPresented: $showingClearDialog) {
                                if let session = viewModel.currentSession {
                                    RemoveLastMessageDialog(
                                        isPresented: $showingClearDialog,
                                        session: session,
                                        onRemove: {
                                            viewModel.removeLastMessage(session.id)
                                        }
                                    )
                                }
                            }
                        }
                        .padding(.trailing, 30)
                    }
                }
            }
        }
        .background(.bar)
        .alert("Clear Chat History", isPresented: $showingDeleteAlert) {
            Button("Cancel") { }
            Button("Clear") {
                if let session = viewModel.currentSession {
                    viewModel.clearSessionHistory(session.id)
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .keyboardShortcut(.return, modifiers: [])
        } message: {
            if let session = viewModel.currentSession {
                Text("Are you sure you want to clear the chat history for '\(session.subject)'?")
            } else {
                Text("Are you sure you want to clear the chat history?")
            }
        }
        .sheet(isPresented: $showingConfiguration) {
            ConfigurationView(shouldRefresh: $shouldRefreshCredentials)
        }
        .onChange(of: shouldRefreshCredentials) { newValue in
            if newValue {
                viewModel.refreshCredentials()
                shouldRefreshCredentials = false
            }
        }
        .onAppear {
            isTextFieldFocused = true
        }
    }
    
    private func sendMessage() {
        guard !userInput.isEmpty && !viewModel.isProcessing else { return }
        let messageToSend = userInput
        userInput = ""  // Clear input immediately
        print(userInput)
        Task {
            await viewModel.processUserInput(messageToSend)
        }
    }
} 
