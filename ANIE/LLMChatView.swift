import SwiftUI

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
    
    var body: some View {
        HSplitView {
            ChatSidebarView(viewModel: viewModel)
            
            VStack(spacing: 0) {
                // Top toolbar
                HStack {
                    Spacer()
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
                    .padding([.top, .trailing], 8)
                }
                
                // Messages ScrollView
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 9) {
                            if let session = viewModel.currentSession {
                                ForEach(session.messages) { message in
                                    MessageView(message: message)
                                        .id(message.id)
                                }
                            }
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 8)
                        .onAppear {
                            scrollProxy = proxy
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                withAnimation {
                                    proxy.scrollTo("bottom", anchor: .bottom)
                                }
                            }
                        }
                        .onChange(of: viewModel.selectedSessionId) { oldId, newId in
                            Task { @MainActor in
                                if let lastMessage = viewModel.currentSession?.messages.last {
                                    await MainActor.run {
                                        withAnimation {
                                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                        }
                                    }
                                }
                            }
                        }
                        
                        Color.clear
                            .frame(height: 1)
                            .id("bottom")
                    }
                    .onChange(of: scrollManager.shouldScrollToBottom) { oldValue, newValue in
                        if newValue {
                            Task { @MainActor in
                                await MainActor.run {
                                    withAnimation {
                                        proxy.scrollTo("bottom", anchor: .bottom)
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Bottom input area
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text("Enter some text (⌘↩ to send)")
                            .foregroundColor(.blue)
                            .font(.system(size: 12))
                            .padding(.leading, 22)
                        
                        Toggle("Local ML", isOn: $useLocalAI)
                            .toggleStyle(.switch)
                            .help("Use local ML for AI/ML related queries")
                            .scaleEffect(0.8)
                        
                        if viewModel.isProcessing {
                            Spacer()
                            ProgressView(value: viewModel.processingProgress, total: 1.0)
                                .progressViewStyle(.linear)
                                .frame(width: 100)
                                .padding(.trailing, 60)
                        }
                    }
                    .padding(.top, 10)
                    
                    HStack(alignment: .bottom) {
                        TextEditor(text: $userInput)
                            .frame(height: 80)
                            .padding(8)
                            .textFieldStyle(.plain)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(.textBackgroundColor))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color(.separatorColor), lineWidth: 1)
                                    )
                            )
                            .font(.system(size: 14))
                            .padding(.horizontal, 18)
                        
                        VStack(spacing: 22) {
                            Button(action: {
                                showingDeleteAlert = true
                            }) {
                                Image(systemName: "trash.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(.red.opacity(0.8))
                                    .background(Circle().fill(Color.white))
                                    .contentShape(Circle())
                            }
                            .buttonStyle(PlainButtonStyle())
                            .keyboardShortcut(.delete, modifiers: .command)
                            .disabled(viewModel.currentSession?.messages.isEmpty ?? true)
                            
                            Button(action: sendMessage) {
                                Image(systemName: "arrow.up.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(userInput.isEmpty || viewModel.isProcessing ? 
                                        Color.black.opacity(0.5) : .blue)
                                    .background(Circle().fill(Color.white))
                                    .contentShape(Circle())
                            }
                            .buttonStyle(PlainButtonStyle())
                            .keyboardShortcut(.return, modifiers: .command)
                            .disabled(userInput.isEmpty || viewModel.isProcessing)
                        }
                        .padding(.trailing, 30)
                        .offset(y: -1)
                    }
                }
                .padding(.bottom, 8)
            }
        }
        .background(.bar)
        .alert("Clear Chat History", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                if let session = viewModel.currentSession {
                    viewModel.clearSessionHistory(session.id)
                }
            }
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
        .onChange(of: shouldRefreshCredentials) { oldValue, newValue in
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
        
        Task {
            await viewModel.processUserInput(messageToSend)
        }
    }
} 