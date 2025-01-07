import SwiftUI

struct NewSessionDialog: View {
    @Binding var isPresented: Bool
    @Binding var subject: String
    var onSubmit: (String) -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // App Icon
            Image(nsImage: NSImage(named: "AppIcon") ?? NSImage())
                .resizable()
                .frame(width: 64, height: 64)
                .padding(.top, 8)
            
            Text("New Chat Session")
                .font(.headline)
            
            TextField("Subject", text: $subject)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 250)
            
            HStack(spacing: 12) {
                Button("Cancel") {
                    subject = ""
                    isPresented = false
                }
                
                Button("Create") {
                    if !subject.isEmpty {
                        onSubmit(subject)
                        subject = ""
                        isPresented = false
                    }
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.return, modifiers: [])
            }
        }
        .padding(20)
        .background(Color(.windowBackgroundColor))
        .cornerRadius(12)
    }
}

struct DeleteSessionDialog: View {
    @Binding var isPresented: Bool
    let session: ChatSession
    var onDelete: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // App Icon
            Image(nsImage: NSImage(named: "AppIcon") ?? NSImage())
                .resizable()
                .frame(width: 64, height: 64)
                .padding(.top, 8)
            
            Text("Delete Session")
                .font(.headline)
            
            Text("Are you sure you want to delete '\(session.subject)' and its history?")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            HStack(spacing: 12) {
                Button("Cancel") {
                    isPresented = false
                }
                
                Button("Delete") {
                    onDelete()
                    isPresented = false
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .keyboardShortcut(.return, modifiers: [])
            }
        }
        .padding(20)
        .frame(width: 300)
        .background(Color(.windowBackgroundColor))
        .cornerRadius(12)
    }
}

struct ChatSidebarView: View {
    @ObservedObject var viewModel: LLMViewModel
    @State private var showingNewSessionAlert = false
    @State private var newSessionSubject = ""
    @State private var sessionToDelete: UUID?
    
    var body: some View {
        VStack {
            // Header with add/remove buttons
            HStack {
                Button(action: {
                    showingNewSessionAlert = true
                }) {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 16))
                        .foregroundColor(.primary)
                        .frame(width: 30, height: 30)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                .onHover { hovering in
                    if hovering {
                        NSCursor.pointingHand.push()
                    } else {
                        NSCursor.pop()
                    }
                }
                
                Spacer()
                
                Button(action: {
                    if let selected = viewModel.selectedSessionId {
                        sessionToDelete = selected
                    }
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.primary)
                        .frame(width: 24, height: 24)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color(.controlBackgroundColor))
                        )
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .frame(width: 32, height: 32)
                .disabled(viewModel.selectedSessionId == nil)
                .onHover { hovering in
                    if hovering && viewModel.selectedSessionId != nil {
                        NSCursor.pointingHand.push()
                    } else {
                        NSCursor.pop()
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            // Sessions list
            List(viewModel.sessions, selection: $viewModel.selectedSessionId) { session in
                Button {
                    viewModel.selectSession(id: session.id)
                } label: {
                    HStack {
                        Text(session.subject)
                            .lineLimit(1)
                        Spacer()
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(session.id == viewModel.selectedSessionId ? 
                        Color.blue.opacity(0.2) : Color.clear)
                    .cornerRadius(4)
                }
                .buttonStyle(PlainButtonStyle())
                .onHover { hovering in
                    if hovering {
                        NSCursor.pointingHand.push()
                    } else {
                        NSCursor.pop()
                    }
                }
            }
        }
        .frame(width: 200)
        .sheet(isPresented: $showingNewSessionAlert) {
            NewSessionDialog(
                isPresented: $showingNewSessionAlert,
                subject: $newSessionSubject,
                onSubmit: { subject in
                    viewModel.addSession(subject: subject)
                }
            )
        }
        .sheet(isPresented: .init(
            get: { sessionToDelete != nil },
            set: { if !$0 { sessionToDelete = nil } }
        )) {
            if let sessionId = sessionToDelete,
               let session = viewModel.sessions.first(where: { $0.id == sessionId }) {
                DeleteSessionDialog(
                    isPresented: .init(
                        get: { sessionToDelete != nil },
                        set: { if !$0 { sessionToDelete = nil } }
                    ),
                    session: session,
                    onDelete: {
                        viewModel.removeSession(id: session.id)
                        sessionToDelete = nil
                    }
                )
            }
        }
    }
} 
