import SwiftUI
import AppKit

struct MessageView: View {
    let message: Message
    @State private var copiedIndex: Int?
    @State private var isCopied = false
    
    private func formatMarkdown(_ text: String) -> AttributedString {
        // First try with full markdown interpretation
        if var fullMarkdown = try? AttributedString(markdown: text, options: .init(
            allowsExtendedAttributes: true,
            interpretedSyntax: .inlineOnlyPreservingWhitespace,
            failurePolicy: .returnPartiallyParsedIfPossible
        )) {

            while let a = fullMarkdown.range(of: "#### ") {
                fullMarkdown.replaceSubrange(a, with: AttributedString(""))
            }
            
            while let a = fullMarkdown.range(of: "### ") {
                fullMarkdown.replaceSubrange(a, with: AttributedString(""))
            }
            
            while let a = fullMarkdown.range(of: "## ") {
                fullMarkdown.replaceSubrange(a, with: AttributedString(""))
            }
            
            while let a = fullMarkdown.range(of: "# ") {
                fullMarkdown.replaceSubrange(a, with: AttributedString(""))
            }

            while let b = fullMarkdown.range(of: "---\n") {
                fullMarkdown.replaceSubrange(b, with: AttributedString(""))
            }
            
            while let b = fullMarkdown.range(of: "- ") {
                fullMarkdown.replaceSubrange(b, with: AttributedString("⏺ "))
            }
            return fullMarkdown
        }
        return AttributedString(text)
    }
    
    var body: some View {
        HStack(alignment: .top) {
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
            
            VStack(alignment: .leading) {
                let codeBlocks = extractCodeBlocks(from: message.content)
                
                if codeBlocks.isEmpty {
                    // Regular message with markdown and copy icon
                    VStack(alignment: .trailing, spacing: 0) {
                        Text(formatMarkdown(message.content))
                            .textSelection(.enabled)
                            .foregroundColor(message.isUser ? .white : .primary)
                            .padding(.horizontal)
                            .padding(.top, 4)
                            .padding(.bottom, 7)
                        
                        if let imageData = message.imageData,
                           let nsImage = NSImage(data: imageData) {
                            Image(nsImage: nsImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxHeight: 300)
                                .padding(.horizontal)
                                .padding(.bottom, 7)
                        }
                        
                        copyButton(for: message.content)
                            .padding(.trailing, 3)
                            .padding(.bottom, 3)
                    }
                    .background(message.isUser ? Color.blue : Color.gray.opacity(0.2))
                    .cornerRadius(11)
                    .frame(maxWidth: .infinity, alignment: message.isUser ? .trailing : .leading)
                } else {
                    // Mixed content with code blocks and markdown
                    ForEach(Array(codeBlocks.enumerated()), id: \.offset) { index, block in
                        VStack(alignment: .trailing, spacing: 0) {
                            if block.isCode {
                                Text(block.content)
                                    .textSelection(.enabled)
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundColor(.white)
                                    .padding(.horizontal)
                                    .padding(.top, 4)
                            } else {
                                Text(formatMarkdown(block.content))
                                    .textSelection(.enabled)
                                    .foregroundColor(message.isUser ? .white : .primary)
                                    .padding(.horizontal)
                                    .padding(.top, 4)
                            }
                            
                            copyButton(for: block.content, index: index)
                                .padding(.trailing, 3)
                                .padding(.bottom, 3)
                        }
                        .background(block.isCode ? Color.black.opacity(0.8) : (message.isUser ? Color.blue : Color.gray.opacity(0.2)))
                        .cornerRadius(11)
                        .frame(maxWidth: .infinity, alignment: message.isUser ? .trailing : .leading)
                    }
                    
                    if let imageData = message.imageData,
                       let nsImage = NSImage(data: imageData) {
                        VStack(alignment: .trailing, spacing: 0) {
                            Image(nsImage: nsImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxHeight: 300)
                                .padding(.horizontal)
                                .padding(.vertical, 7)
                        }
                        .background(message.isUser ? Color.blue : Color.gray.opacity(0.2))
                        .cornerRadius(11)
                        .frame(maxWidth: .infinity, alignment: message.isUser ? .trailing : .leading)
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
            ZStack {
                // Background with border
                RoundedRectangle(cornerRadius: 7)
                    .fill(Color.black.opacity(0.15))
                    .frame(width: 32, height: 32)
                
                // Icon
                Image(systemName: isCopiedState ? "checkmark" : "doc.on.doc")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isCopiedState ? Color.green : .white)
            }
            .contentShape(Rectangle())  // Make entire area clickable
        }
        .buttonStyle(PlainButtonStyle())
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
