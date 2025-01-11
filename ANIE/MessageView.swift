import SwiftUI
import AppKit


class MessageObserver: ObservableObject {
    static let shared = MessageObserver()
    @Published private(set) var maxWidthX: CGFloat = 600
    
    init() {
        // Set initial value
        updateMaxWidth()
        
        // Observe window size changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidResize),
            name: NSWindow.didResizeNotification,
            object: nil
        )
    }
    
    @objc private func windowDidResize(_ notification: Notification) {
        updateMaxWidth()
    }
    
    private func updateMaxWidth() {
        if let windowWidth = NSApp.windows.first?.frame.size.width {
            maxWidthX = windowWidth / 1.5
        }
    }
}


struct MessageView: View {
    let message: Message
    @StateObject private var messageObserver = MessageObserver.shared

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            if !message.isUser {
                VStack(spacing: 2) {
                    Text("ANIE")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 3)
                        .padding(.bottom, 1)
                    
                    if message.usedLocalAI {
                        Text("🧠")
                            .font(.system(size: 14))
                            .padding(.bottom, 2)
                    } else if message.usedBERT {
                        Text("🤖")
                            .font(.system(size: 14))
                            .padding(.bottom, 2)
                    }
                }
                .frame(width: 40, alignment: .trailing)
            }
            
            if message.isError {
                // Error message - always red background with white text
                VStack(alignment: .trailing, spacing: 0) {
                    Text(message.content)
                        .textSelection(.enabled)
                        .foregroundColor(.white)
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                }
                .background(Color.red)
                .cornerRadius(11)
                .padding(.leading, 5)
                .frame(maxWidth: .infinity, alignment: .leading)
            } else if message.isUser {
                HStack (alignment: .top) {
                        Spacer()
                        UserMessageView(message: message)
                        .frame(width: messageObserver.maxWidthX, alignment: .trailing)
                        .padding(.trailing, 5)
                }
            } else {
                HStack (alignment: .top) {
                    AIMessageView(message: message)
                        .frame(width:  messageObserver.maxWidthX, alignment: .leading)
                        .padding(.leading, 5)
                        Spacer()
                }
            }
            
            if message.isUser {
                Text("You")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 40, alignment: .leading)
            }
        }
        .padding(.horizontal, 7)
        .transaction { transaction in
            transaction.animation = nil
        }
    }
}



      







