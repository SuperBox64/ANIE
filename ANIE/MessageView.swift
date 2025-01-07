import SwiftUI
import AppKit

struct MessageView: View {
    let message: Message
    @State private var copiedIndex: Int?
    @State private var isHovering = false
    @State private var isCopied = false
    
    var body: some View {
        HStack(alignment: .top) {
            if !message.isUser {
                VStack(spacing: 2) {
                    Text("ANIE")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 3)
                    
                    if message.usedBERT {
                        Text("🤖")
                            .font(.system(size: 16))
                            .scaleEffect(1.2)
                    }
                }
                .frame(width: 40, alignment: .trailing)
            }
            
            VStack(alignment: .leading) {
                let codeBlocks = extractCodeBlocks(from: message.content)
                
                if codeBlocks.isEmpty {
                    // Regular message with copy icon
                    VStack(alignment: .trailing, spacing: 0) {
                        Text(message.content)
                            .padding(.horizontal)
                            .padding(.top, 4)
                            .padding(.bottom, 7)
                        
                        copyButton(for: message.content)
                            .padding(4)
                            .background(Color.black.opacity(0.15))
                            .cornerRadius(7)
                            .padding([.bottom, .trailing], 4)
                    }
                    .background(message.isUser ? Color.blue : Color.gray.opacity(0.2))
                    .cornerRadius(11)
                    .frame(maxWidth: 600, alignment: message.isUser ? .trailing : .leading)
                } else {
                    // Code blocks with copy icons
                    ForEach(Array(codeBlocks.enumerated()), id: \.offset) { index, block in
                        VStack(alignment: .trailing, spacing: 0) {
                            Text(block.content)
                                .padding(.horizontal)
                                .padding(.top, 4)
                                .padding(.bottom, 7)
                                .font(block.isCode ? .system(.body, design: .monospaced) : .body)
                            
                            copyButton(for: block.content, index: index)
                                .padding(4)
                                .background(Color.black.opacity(0.15))
                                .cornerRadius(7)
                                .padding([.bottom, .trailing], 4)
                        }
                        .background(block.isCode ? Color.black.opacity(0.8) : (message.isUser ? Color.blue : Color.gray.opacity(0.2)))
                        .cornerRadius(11)
                        .frame(maxWidth: 600, alignment: message.isUser ? .trailing : .leading)
                    }
                }
            }
            .padding(.horizontal, 7)
            
            if message.isUser {
                Text("You")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 40, alignment: .leading)
            }
        }
    }
    
    private func copyButton(for content: String, index: Int? = nil) -> some View {
        let isCopiedState = index != nil ? copiedIndex == index : isCopied
        
        return Button(action: {
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(content, forType: .string)
            
            if let idx = index {
                copiedIndex = idx
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    copiedIndex = nil
                }
            } else {
                isCopied = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    isCopied = false
                }
            }
        }) {
            Image(systemName: isCopiedState ? "checkmark" : "doc.on.doc")
                .font(.system(size: 12, weight: .medium))
                .frame(width: 24, height: 24)
                .foregroundColor(isCopiedState ? Color.green : .white)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            isHovering = hovering
        }
    }
    
    private func extractCodeBlocks(from text: String) -> [(content: String, isCode: Bool)] {
        var blocks: [(String, Bool)] = []
        var currentText = ""
        var isInCodeBlock = false
        
        let lines = text.components(separatedBy: .newlines)
        
        // Code indicators
        let codeKeywords = Set(["func", "class", "struct", "import", "var", "let", "enum", "protocol", "extension"])
        let syntaxPatterns = [
            "^\\s*[a-zA-Z_][a-zA-Z0-9_]*\\s*[:{]\\s*$",  // Class/struct/enum declarations
            "^\\s*\\}\\s*$",  // Closing braces
            "^\\s*[a-zA-Z_][a-zA-Z0-9_]*\\s*\\([^)]*\\)\\s*(?:->|{)\\s*$",  // Function declarations
            "^\\s*@[a-zA-Z][a-zA-Z0-9_]*\\s*$",  // Decorators/attributes
            "^\\s*import\\s+[a-zA-Z][a-zA-Z0-9_]*\\s*$"  // Import statements
        ]
        
        func looksLikeCode(_ text: String) -> Bool {
            let lines = text.components(separatedBy: .newlines)
            var codeScore = 0
            
            for line in lines {
                // Check for code keywords
                let words = line.components(separatedBy: .whitespaces)
                if words.first.map({ codeKeywords.contains($0) }) ?? false {
                    codeScore += 2
                }
                
                // Check for syntax patterns
                if syntaxPatterns.contains(where: { pattern in
                    line.range(of: pattern, options: .regularExpression) != nil
                }) {
                    codeScore += 2
                }
                
                // Check for indentation
                if line.hasPrefix("    ") || line.hasPrefix("\t") {
                    codeScore += 1
                }
                
                // Check for special characters common in code
                if line.contains("{") || line.contains("}") || line.contains(";") {
                    codeScore += 1
                }
            }
            
            // Consider it code if score exceeds threshold relative to line count
            return codeScore >= max(3, lines.count)
        }
        
        for line in lines {
            if line.hasPrefix("```") {
                if !currentText.isEmpty {
                    // If not explicitly marked as code, use ML detection
                    let isCode = isInCodeBlock || looksLikeCode(currentText)
                    blocks.append((currentText, isCode))
                    currentText = ""
                }
                isInCodeBlock.toggle()
                continue
            }
            
            if !currentText.isEmpty {
                currentText += "\n"
            }
            currentText += line
        }
        
        if !currentText.isEmpty {
            // For the last block, use ML detection if not explicitly marked
            let isCode = isInCodeBlock || looksLikeCode(currentText)
            blocks.append((currentText, isCode))
        }
        
        return blocks
    }
} 
