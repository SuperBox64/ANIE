import SwiftUI
import AppKit

struct AIMessageView: View {
    let message: Message
    @Environment(\.colorScheme) private var colorScheme
    @State private var copiedIndex: Int?
    @State private var isCopied = false
    let searchTerm: String
    let isCurrentSearchResult: Bool
 
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            let blocks = extractCodeBlocks(from: message.content)
          
            ForEach(Array(blocks.enumerated()), id: \.offset) { index, block in
                Group {
                    if block.isCode {
                        let swiftKeywords = ["func ", "class ", "struct ", "print", "var ", "enum ", "case ", "Swift ", "```swift"]
                        let isSwift = swiftKeywords.contains { block.content.contains($0) }
                        
                        ZStack(alignment: .bottomTrailing) {
                            Text(formatSwiftCode(block.content, colorScheme: colorScheme, searchTerm: searchTerm, isCurrentSearchResult: isCurrentSearchResult))
                                .textSelection(.enabled)
                                .padding(6)
                                .padding(.trailing, 38)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            copyButton(for: block.content, index: index)
                                .padding(.trailing, 3)
                                .padding(.bottom, 3)
                        }
                        .background(Color.black.opacity(0.7))
                       
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .cornerRadius(8)
                        .padding(6)
                    } else {
                        Text(formatMarkdown(block.content, colorScheme: colorScheme, searchTerm: searchTerm, isCurrentSearchResult: isCurrentSearchResult))
                            .textSelection(.enabled)
                            .foregroundColor(Color(nsColor: NSColor.labelColor))
                    }
                }
                .transaction { transaction in
                    transaction.animation = nil
                }
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 6)
        .background(Color(nsColor: NSColor.windowBackgroundColor))
        .cornerRadius(11)
    }
    
    private func copyButton(for content: String, index: Int? = nil) -> some View {
        let isCopiedState = index != nil ? copiedIndex == index : isCopied
        
        return Button(action: {
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(content, forType: .string)
            
            withAnimation(nil) {
                if let idx = index {
                    copiedIndex = idx
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation(nil) {
                            copiedIndex = nil
                        }
                    }
                } else {
                    isCopied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation(nil) {
                            isCopied = false
                        }
                    }
                }
            }
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 7)
                    .fill(colorScheme == .dark ? 
                        Color.black.opacity(0.15) : 
                        Color(nsColor: .windowBackgroundColor))
                    .frame(width: 32, height: 32)
                
                Image(systemName: isCopiedState ? "checkmark" : "doc.on.doc")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isCopiedState ? Color.green : 
                        (colorScheme == .dark ? .white : .black))
                    .animation(.spring(response: 0.2), value: isCopiedState)
                    .scaleEffect(isCopiedState ? 1.2 : 1.0)
                    .rotationEffect(.degrees(isCopiedState ? 0 : -360))
            }
            .contentShape(Rectangle())
            .transaction { transaction in
                transaction.animation = nil
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
} 
 
