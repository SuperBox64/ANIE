import SwiftUI
import AppKit


class MessageObserver: ObservableObject {
    static let shared = MessageObserver()
    //@Published private(set) var maxWidthX: CGFloat = 600
    private var windowObserver: NSObjectProtocol?
    private var windowCreationObserver: NSObjectProtocol?
    
    private init() {
        // Set initial value and start observing
        setupObservers()
    }
    
    private func setupObservers() {
        // Observe window resizing
//        windowObserver = NotificationCenter.default.addObserver(
//            forName: NSWindow.didResizeNotification,
//            object: nil,
//            queue: .main
//        ) { [weak self] _ in
//            self?.updateMaxWidth()
//        }
//        
//        // Observe window creation/changes
//        windowCreationObserver = NotificationCenter.default.addObserver(
//            forName: NSWindow.didBecomeKeyNotification,
//            object: nil,
//            queue: .main
//        ) { [weak self] _ in
//            self?.updateMaxWidth()
//        }
        
        // Initial update
        //updateMaxWidth()
    }
    
//    private func updateMaxWidth() {
//        // Get the key window first, fall back to first window if needed
//        if let window = NSApp.keyWindow ?? NSApp.windows.first {
//            let newWidth = window.frame.size.width / 1.5
//            // Only update if width actually changed
//            if abs(newWidth - maxWidthX) > 1 {
//                maxWidthX = newWidth
//            }
//        }
//  }
    
//    deinit {
//        if let observer = windowObserver {
//            NotificationCenter.default.removeObserver(observer)
//        }
//        if let observer = windowCreationObserver {
//            NotificationCenter.default.removeObserver(observer)
//        }
//    }
}


struct MessageView: View {
    let message: Message
    @ObservedObject private var messageObserver = MessageObserver.shared
    let searchTerm: String
    let isCurrentSearchResult: Bool
    @Binding var isOmitted: Bool
    let showCheckbox: Bool  // Only show checkbox for user messages
    
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
            // Only show checkbox for user messages
            if showCheckbox {
                Toggle("", isOn: Binding(
                    get: { !isOmitted },  // Invert the binding
                    set: { newValue in
                        isOmitted = !newValue  // Invert the value
                    }
                ))
                    .toggleStyle(CheckboxToggleStyle())
                    .padding(.trailing, 8)
                    .padding(.top, 3)
            }
            
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
                .opacity(isOmitted ? 0.5 : 1.0)  // No change needed here since logic is correct
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
                .opacity(isOmitted ? 0.5 : 1.0)  // No change needed here since logic is correct
            } else if message.isUser {
                HStack (alignment: .top) {
                    Spacer()
                    UserMessageView(message: message, searchTerm: searchTerm, isCurrentSearchResult: isCurrentSearchResult)
                        .overlay(
                            RoundedRectangle(cornerRadius: 11)
                                .stroke(isCurrentSearchResult ? Color.yellow : Color.clear, lineWidth: 2)
                        )
                        .frame(width: .infinity, alignment: .trailing)
                        .padding(.trailing, 5)
                        .opacity(isOmitted ? 0.5 : 1.0)  // No change needed here since logic is correct
                }
            } else {
                HStack (alignment: .top) {
                    AIMessageView(message: message, searchTerm: searchTerm, isCurrentSearchResult: isCurrentSearchResult)
                        .overlay(
                            RoundedRectangle(cornerRadius: 11)
                                .stroke(isCurrentSearchResult ? Color.yellow : Color.clear, lineWidth: 2)
                        )
                        .frame(width: .infinity, alignment: .leading)
                        .padding(.leading, 5)
                        .opacity(isOmitted ? 0.5 : 1.0)  // No change needed here since logic is correct
                    Spacer()
                }
            }
            
            if message.isUser {
                Text("You")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 40, alignment: .leading)
                    .opacity(isOmitted ? 0.5 : 1.0)  // No change needed here since logic is correct
            }
        }
        .padding(.horizontal, 7)
        .padding(.top, 16)
        .transaction { transaction in
            transaction.animation = nil
        }
    }
}



      







