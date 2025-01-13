import SwiftUI
import AppKit


class MessageObserver: ObservableObject {
    static let shared = MessageObserver()
    @Published private(set) var maxWidthX: CGFloat = 600
    
    private init() {
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
    @ObservedObject private var messageObserver = MessageObserver.shared
    let searchTerm: String
    let isCurrentSearchResult: Bool
    
    private func highlightedText(_ text: String) -> AnyView {
        guard !searchTerm.isEmpty else { return AnyView(Text(text)) }
        
        let searchTermLowercased = searchTerm.lowercased()
        let textLowercased = text.lowercased()
        
        if let range = textLowercased.range(of: searchTermLowercased) {
            return AnyView(HStack(spacing: 0) {
                Text(String(text[..<range.lowerBound]))
                Text(String(text[range]))
                    .foregroundColor(.black)
                    .background(Color.yellow)
                    .bold()
                Text(String(text[range.upperBound...]))
            })
        }
        
        return AnyView(Text(text))
    }

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
                    highlightedText(message.content)
                        .textSelection(.enabled)
                        .foregroundColor(.white)
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(Color.red)
                        .cornerRadius(11)
                        .overlay(
                            RoundedRectangle(cornerRadius: 11)
                                .stroke(isCurrentSearchResult ? Color.yellow : Color.clear, lineWidth: 2)
                        )
                }
                .padding(.leading, 5)
                .frame(maxWidth: .infinity, alignment: .leading)
            } else if message.isUser {
                HStack (alignment: .top) {
                    Spacer()
                    UserMessageView(message: message, searchTerm: searchTerm, isCurrentSearchResult: isCurrentSearchResult)
                        //.border(Color.red, width: 1)
                        .overlay(
                            RoundedRectangle(cornerRadius: 11)
                                .stroke(isCurrentSearchResult ? Color.yellow : Color.clear, lineWidth: 2)
                        )
                        .frame(width: messageObserver.maxWidthX, alignment: .trailing)
                        .padding(.trailing, 5)
                }
            } else {
                HStack (alignment: .top) {
                    AIMessageView(message: message, searchTerm: searchTerm, isCurrentSearchResult: isCurrentSearchResult)
                        //.border(Color.red, width: 1)
                        .overlay(
                            RoundedRectangle(cornerRadius: 11)
                                .stroke(isCurrentSearchResult ? Color.yellow : Color.clear, lineWidth: 2)
                        )
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
        .padding(.top, 16)
        .transaction { transaction in
            transaction.animation = nil
        }
    }
}



      







