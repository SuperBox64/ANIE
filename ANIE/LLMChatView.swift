import SwiftUI

struct LLMChatView: View {
    @ObservedObject var viewModel: LLMViewModel
    @State private var userInput: String = ""
    @State private var isHovering = false
    @State private var scrollProxy: ScrollViewProxy? = nil
    @State private var lastMessageId: UUID? = nil
    @State private var showingDeleteAlert = false
    @State private var showingConfiguration = false
    @State private var shouldRefreshCredentials = false
    @State private var initialScrollDone = false
    
    var body: some View {
        HSplitView {
            ChatSidebarView(viewModel: viewModel)
            
            VStack(spacing: 0) {
                // Add settings button to top-right
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
                ScrollView {
                    ScrollViewReader { proxy in
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
                        .onChange(of: viewModel.currentSession?.messages.count) { oldCount, newCount in
                            if let lastMessage = viewModel.currentSession?.messages.last {
                                withAnimation {
                                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                }
                            }
                        }
                        .onAppear {
                            scrollProxy = proxy
                            // Scroll to top when view first appears
                            if !initialScrollDone {
                                if let firstMessage = viewModel.currentSession?.messages.first {
                                    proxy.scrollTo(firstMessage.id, anchor: .top)
                                    initialScrollDone = true
                                }
                            }
                        }
                        // Add this to handle session changes
                        .onChange(of: viewModel.selectedSessionId) { oldId, newId in
                            initialScrollDone = false
                            if let firstMessage = viewModel.currentSession?.messages.first {
                                proxy.scrollTo(firstMessage.id, anchor: .top)
                                initialScrollDone = true
                            }
                        }
                    }
                }
                
                // Progress bar
                if viewModel.isProcessing {
                    ProgressView(value: viewModel.processingProgress, total: 1.0)
                        .progressViewStyle(.linear)
                        .padding(.horizontal)
                        .padding(.top, 8)
                        .transition(.opacity)
                }
                
                // Bottom input area
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text("Enter some text (⌘↩ to send)")
                            .foregroundColor(.blue)
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
    }
    
    private func sendMessage() {
        guard !userInput.isEmpty && !viewModel.isProcessing else { return }
        Task {
            await viewModel.processUserInput(userInput)
            userInput = ""
        }
    }
} 