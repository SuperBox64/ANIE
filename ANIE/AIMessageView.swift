import SwiftUI
import AppKit

struct AIMessageView: View {
    let message: Message
    let isSelected: Bool
    @Environment(\.colorScheme) private var colorScheme
    @State private var copiedIndex: Int?
    @State private var isCopied = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            let blocks = extractCodeBlocks(from: message.content)
            ForEach(Array(blocks.enumerated()), id: \.offset) { index, block in
                Group {
                    if block.isCode {
                        let isCode = true
                        
                        ZStack(alignment: .bottomTrailing) {
                            Text(formatSwiftCode(block.content, colorScheme: colorScheme))
                                .textSelection(.enabled)
                                .padding(6)
                                .padding(.trailing, 38)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            copyButton(for: block.content, index: index)
                                .padding(.trailing, 3)
                                .padding(.bottom, 3)
                        }
                        .background(isCode ?
                            (colorScheme == .dark ? Color.black : Color.white) :
                            Color(nsColor: NSColor.windowBackgroundColor).opacity(0.3))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .cornerRadius(8)
                        .padding(6)
                    } else {
                        Text(formatMarkdown(block.content))
                            .textSelection(.enabled)
                    }
                }
                .transaction { transaction in
                    transaction.animation = nil
                }
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 11)
                .fill(isSelected ? Color.blue.opacity(0.3) : 
                    (colorScheme == .dark ? Color(.windowBackgroundColor) : Color.white))
                .overlay(
                    RoundedRectangle(cornerRadius: 11)
                        .stroke(Color(.separatorColor), lineWidth: 1)
                )
        )
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
 
