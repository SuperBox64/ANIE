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
            mainChatView
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
                Text("Are you sure you want to clear the history?")
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
    
    private var mainChatView: some View {
        VStack(spacing: 0) {
            settingsButton
            messagesScrollView
            if viewModel.isProcessing {
                progressBar
            }
            bottomInputArea
        }
    }
    
    private var settingsButton: some View {
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
    }
    
    private var messagesScrollView: some View {
        ScrollView {
            ScrollViewReader { proxy in
                messagesList(proxy: proxy)
            }
        }
    }
    
    private func messagesList(proxy: ScrollViewProxy) -> some View {
        LazyVStack(spacing: 9) {
            if let session = viewModel.currentSession {
                ForEach(session.messages, id: \.timestamp) { message in
                    MessageView(message: message)
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 8)
        .onChange(of: viewModel.currentSession?.messages.count) { oldCount, newCount in
            if let lastMessage = viewModel.currentSession?.messages.last {
                withAnimation {
                    proxy.scrollTo(lastMessage.timestamp, anchor: .bottom)
                }
            }
        }
        .onAppear { handleScrollViewAppear(proxy: proxy) }
        .onChange(of: viewModel.selectedSessionId) { oldId, newId in
            if let lastMessage = viewModel.currentSession?.messages.last {
                withAnimation {
                    proxy.scrollTo(lastMessage.timestamp, anchor: .bottom)
                }
            }
        }
    }
    
    private func handleScrollViewAppear(proxy: ScrollViewProxy) {
        scrollProxy = proxy
        if !initialScrollDone {
            if let firstMessage = viewModel.currentSession?.messages.first {
                proxy.scrollTo(firstMessage.timestamp, anchor: .top)
                initialScrollDone = true
            }
        }
    }
    
    private var progressBar: some View {
        ProgressView(value: viewModel.processingProgress, total: 1.0)
            .progressViewStyle(.linear)
            .padding(.horizontal)
            .padding(.top, 8)
            .transition(.opacity)
    }
    
    private var bottomInputArea: some View {
        VStack(alignment: .leading, spacing: 2) {
            inputHeader
            inputControls
        }
        .padding(.bottom, 8)
    }
    
    private var inputHeader: some View {
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
    }
    
    private var inputControls: some View {
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
            
            controlButtons
        }
    }
    
    private var controlButtons: some View {
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
    
    private func sendMessage() {
        guard !userInput.isEmpty && !viewModel.isProcessing else { return }
        Task {
            await viewModel.processUserInput(userInput)
            userInput = ""
        }
    }
} 