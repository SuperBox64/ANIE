import SwiftUI
import AppKit
import ANIE


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
        DispatchQueue.main.async {
            self.updateMaxWidth()
        }
    }
    
    private func updateMaxWidth() {
        if let windowWidth = NSApp.windows.first?.frame.size.width {
            maxWidthX = windowWidth / 1.5
        }
    }
}


struct MessageView: View {
    let message: Message
    let isSelected: Bool
    @ObservedObject private var messageObserver = MessageObserver.shared
    
    var body: some View {
        VStack(alignment: .leading) {
            if message.isError {
                ErrorMessageView(message: message)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else if message.isUser {
                HStack (alignment: .top) {
                    Spacer()
                    UserMessageView(message: message, isSelected: isSelected)
                        .frame(width: messageObserver.maxWidthX, alignment: .trailing)
                        .padding(.trailing, 5)
                }
            } else {
                HStack (alignment: .top) {
                    AIMessageView(message: message, isSelected: isSelected)
                        .frame(width: messageObserver.maxWidthX, alignment: .leading)
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


struct ErrorMessageView: View {
    let message: Message
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(message.content)
                .textSelection(.enabled)
                .foregroundColor(.red)
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 11)
                        .fill(colorScheme == .dark ? Color(.controlBackgroundColor) : Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 11)
                                .stroke(Color.red.opacity(0.3), lineWidth: 1)
                        )
                )
        }
    }
}



      







