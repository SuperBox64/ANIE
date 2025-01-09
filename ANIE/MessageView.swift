import SwiftUI
import AppKit

struct MessageView: View {
    let message: Message
    @State private var copiedIndex: Int?
    @State private var isCopied = false
    
    private func formatSwiftCode(_ code: String) -> AttributedString {
        var result = AttributedString(code)
        
        // Define Xcode's exact colors to match the bright theme
        let keywordColor = Color(nsColor: NSColor(red: 255/255, green: 112/255, blue: 167/255, alpha: 1.0))    // Bright pink for keywords
        let typeColor = Color(nsColor: NSColor(red: 154/255, green: 134/255, blue: 255/255, alpha: 1.0))       // Bright purple for Int/types
        let functionCallColor = Color(nsColor: NSColor(red: 103/255, green: 243/255, blue: 255/255, alpha: 1.0))// Bright teal for function calls
        let stringColor = Color(nsColor: NSColor(red: 255/255, green: 128/255, blue: 89/255, alpha: 1.0))      // Bright coral for strings
        let numberColor = Color(nsColor: NSColor(red: 255/255, green: 172/255, blue: 48/255, alpha: 1.0))      // Bright gold for numbers
        let operatorColor = Color(nsColor: NSColor(red: 103/255, green: 243/255, blue: 255/255, alpha: 1.0))   // Bright teal for operators
        let printColor = Color(nsColor: NSColor(red: 154/255, green: 134/255, blue: 255/255, alpha: 1.0))      // Bright purple for print
        let parameterColor = Color.white                                                                        // Pure white for parameters
        let defaultColor = Color.white                                                                          // Pure white for default text
        
        // Comment colors with proper opacity for visibility
        let regularCommentColor = Color(nsColor: NSColor(red: 108/255, green: 121/255, blue: 134/255, alpha: 1.0))    // Regular comments
        let docCommentColor = Color(nsColor: NSColor(red: 108/255, green: 121/255, blue: 134/255, alpha: 1.0))        // Doc comments (///)
        let markCommentColor = Color(nsColor: NSColor(red: 180/255, green: 190/255, blue: 200/255, alpha: 1.0))       // MARK/TODO comments - brighter gray
        
        // Set default text color
        result.foregroundColor = defaultColor
        
        let text = code as NSString
        let range = NSRange(location: 0, length: text.length)
        
        // Keywords (pink)
        let keywords = ["struct","class","func", "if", "else", "return", "let", "var"]
        
        // Common Swift types (purple)
        let types = ["Int", "String", "Double", "Float", "Bool"]
        
        // Special functions (purple)
        let specialFunctions = ["print"]
        
        // Operators (teal)
        let operators = ["==", "!=", ">=", "<=", "&&", "||", "!", "+", "-", "*", "/", "%", "^", "&", "|", "~", ".", "->", "<", ">", "=", "??", "?", ":", "_"]
        
        // Function parameters (must be first to avoid conflicts)
        let paramPattern = "(?<=\\()([^)]+)(?=\\))"
        if let regex = try? NSRegularExpression(pattern: paramPattern, options: []) {
            let matches = regex.matches(in: code, range: range)
            for match in matches.reversed() {
                if let stringRange = Range(match.range, in: code),
                   let attributedRange = Range(stringRange, in: result) {
                    var paramAttr = AttributedString(String(code[stringRange]))
                    paramAttr.foregroundColor = parameterColor
                    result.replaceSubrange(attributedRange, with: paramAttr)
                }
            }
        }
        
        // Special functions like print (must be before other function calls)
        for function in specialFunctions {
            let pattern = "\\b\(function)\\b(?=\\s*\\()"
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let matches = regex.matches(in: code, range: range)
                for match in matches.reversed() {
                    if let stringRange = Range(match.range, in: code),
                       let attributedRange = Range(stringRange, in: result) {
                        var functionAttr = AttributedString(String(code[stringRange]))
                        functionAttr.foregroundColor = printColor
                        result.replaceSubrange(attributedRange, with: functionAttr)
                    }
                }
            }
        }
        
        // String interpolation
        let interpolationPattern = "\\\\\\([^)]+\\)"
        if let regex = try? NSRegularExpression(pattern: interpolationPattern, options: []) {
            let matches = regex.matches(in: code, range: range)
            for match in matches.reversed() {
                if let stringRange = Range(match.range, in: code),
                   let attributedRange = Range(stringRange, in: result) {
                    var interpolationAttr = AttributedString(String(code[stringRange]))
                    interpolationAttr.foregroundColor = defaultColor
                    result.replaceSubrange(attributedRange, with: interpolationAttr)
                }
            }
        }
        
        // Strings (including the quotes)
        let stringPattern = #""[^"\\]*(?:\\.[^"\\]*)*""#
        if let regex = try? NSRegularExpression(pattern: stringPattern, options: [.dotMatchesLineSeparators]) {
            let matches = regex.matches(in: code, range: range)
            for match in matches.reversed() {
                if let stringRange = Range(match.range, in: code),
                   let attributedRange = Range(stringRange, in: result) {
                    var stringAttr = AttributedString(String(code[stringRange]))
                    stringAttr.foregroundColor = stringColor
                    result.replaceSubrange(attributedRange, with: stringAttr)
                }
            }
        }
        
        // Numbers
        let numberPattern = "\\b\\d+(\\.\\d+)?\\b"
        if let regex = try? NSRegularExpression(pattern: numberPattern, options: []) {
            let matches = regex.matches(in: code, range: range)
            for match in matches.reversed() {
                if let stringRange = Range(match.range, in: code),
                   let attributedRange = Range(stringRange, in: result) {
                    var numberAttr = AttributedString(String(code[stringRange]))
                    numberAttr.foregroundColor = numberColor
                    result.replaceSubrange(attributedRange, with: numberAttr)
                }
            }
        }
        
        // Function calls (after special functions are handled)
        let functionCallPattern = "\\b[a-zA-Z_][a-zA-Z0-9_]*(?=\\s*\\()"
        if let regex = try? NSRegularExpression(pattern: functionCallPattern, options: []) {
            let matches = regex.matches(in: code, range: range)
            for match in matches.reversed() {
                if let stringRange = Range(match.range, in: code),
                   let attributedRange = Range(stringRange, in: result) {
                    let functionName = String(code[stringRange])
                    if !keywords.contains(functionName) && !types.contains(functionName) && !specialFunctions.contains(functionName) {
                        var functionAttr = AttributedString(functionName)
                        functionAttr.foregroundColor = functionCallColor
                        result.replaceSubrange(attributedRange, with: functionAttr)
                    }
                }
            }
        }
        
        // Types (must be before keywords to handle return types correctly)
        for type in types {
            let pattern = "\\b\(type)\\b"
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let matches = regex.matches(in: code, range: range)
                for match in matches.reversed() {
                    if let stringRange = Range(match.range, in: code),
                       let attributedRange = Range(stringRange, in: result) {
                        var typeAttr = AttributedString(String(code[stringRange]))
                        typeAttr.foregroundColor = typeColor
                        result.replaceSubrange(attributedRange, with: typeAttr)
                    }
                }
            }
        }
        
        // Keywords
        for keyword in keywords {
            let pattern = "\\b\(keyword)\\b"
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let matches = regex.matches(in: code, range: range)
                for match in matches.reversed() {
                    if let stringRange = Range(match.range, in: code),
                       let attributedRange = Range(stringRange, in: result) {
                        var keywordAttr = AttributedString(String(code[stringRange]))
                        keywordAttr.foregroundColor = keywordColor
                        result.replaceSubrange(attributedRange, with: keywordAttr)
                    }
                }
            }
        }
        
        // Operators (must be last to handle compound operators correctly)
        for op in operators.sorted(by: { $0.count > $1.count }) {  // Sort by length to handle longer operators first
            let escapedOp = NSRegularExpression.escapedPattern(for: op)
            if let regex = try? NSRegularExpression(pattern: escapedOp, options: []) {
                let matches = regex.matches(in: code, range: range)
                for match in matches.reversed() {
                    if let stringRange = Range(match.range, in: code),
                       let attributedRange = Range(stringRange, in: result) {
                        var operatorAttr = AttributedString(String(code[stringRange]))
                        operatorAttr.foregroundColor = operatorColor
                        result.replaceSubrange(attributedRange, with: operatorAttr)
                    }
                }
            }
        }
        
        // Comments must be handled last to allow syntax highlighting of code before comments
        let todoPattern = "//\\s*TODO:.*$"
        let markPattern = "//\\s*MARK:.*$"
        let docPattern = "///.*$"
        let commentPattern = "//(?!/|\\s*MARK:|\\s*TODO:).*$"
        
        // TODO comments
        if let regex = try? NSRegularExpression(pattern: todoPattern, options: [.anchorsMatchLines]) {
            let matches = regex.matches(in: code, range: range)
            for match in matches.reversed() {
                if let stringRange = Range(match.range, in: code),
                   let attributedRange = Range(stringRange, in: result) {
                    var commentAttr = AttributedString(String(code[stringRange]))
                    commentAttr.foregroundColor = markCommentColor  // Using same color as MARK
                    result.replaceSubrange(attributedRange, with: commentAttr)
                }
            }
        }
        
        // MARK comments
        if let regex = try? NSRegularExpression(pattern: markPattern, options: [.anchorsMatchLines]) {
            let matches = regex.matches(in: code, range: range)
            for match in matches.reversed() {
                if let stringRange = Range(match.range, in: code),
                   let attributedRange = Range(stringRange, in: result) {
                    var commentAttr = AttributedString(String(code[stringRange]))
                    commentAttr.foregroundColor = markCommentColor
                    result.replaceSubrange(attributedRange, with: commentAttr)
                }
            }
        }
        
        // Doc comments (///)
        if let regex = try? NSRegularExpression(pattern: docPattern, options: [.anchorsMatchLines]) {
            let matches = regex.matches(in: code, range: range)
            for match in matches.reversed() {
                if let stringRange = Range(match.range, in: code),
                   let attributedRange = Range(stringRange, in: result) {
                    var commentAttr = AttributedString(String(code[stringRange]))
                    commentAttr.foregroundColor = docCommentColor
                    result.replaceSubrange(attributedRange, with: commentAttr)
                }
            }
        }
        
        // Regular comments (//)
        if let regex = try? NSRegularExpression(pattern: commentPattern, options: [.anchorsMatchLines]) {
            let matches = regex.matches(in: code, range: range)
            for match in matches.reversed() {
                if let stringRange = Range(match.range, in: code),
                   let attributedRange = Range(stringRange, in: result) {
                    var commentAttr = AttributedString(String(code[stringRange]))
                    commentAttr.foregroundColor = regularCommentColor
                    result.replaceSubrange(attributedRange, with: commentAttr)
                }
            }
        }
        
        return result
    }
    
    private func formatMarkdown(_ text: String) -> AttributedString {
        // Check if this is an error message (starts with "Error:" or contains specific error patterns)
        if text.hasPrefix("Error:") || text.contains("API Error:") {
            var errorAttr = AttributedString(text)
            errorAttr.foregroundColor = .white
            return errorAttr
        }
        
        // Split into code blocks and regular text
        let parts = text.components(separatedBy: "```")
        var result = AttributedString()
        
        for (index, part) in parts.enumerated() {
            if index % 2 == 0 {
                // Regular text - process normally
                let cleanedText = part.components(separatedBy: .newlines)
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                    .joined(separator: "\n")
                
                if var processed = try? AttributedString(markdown: cleanedText, options: .init(
                    allowsExtendedAttributes: true,
                    interpretedSyntax: .inlineOnlyPreservingWhitespace,
                    failurePolicy: .returnPartiallyParsedIfPossible
                )) {
                    // Define all markers to remove
                    let headerMarkers = ["#### ", "### ", "## ", "# "]
                    
                    // Remove header markers
                    for marker in headerMarkers {
                        while let range = processed.range(of: marker) {
                            processed.replaceSubrange(range, with: AttributedString(""))
                        }
                    }
                    
                    // Replace horizontal rules
                    while let range = processed.range(of: "---\n") {
                        processed.replaceSubrange(range, with: AttributedString(""))
                    }
                    
                    // Replace list markers
                    while let range = processed.range(of: "- ") {
                        processed.replaceSubrange(range, with: AttributedString("⏺ "))
                    }
                    
                    result += processed
                }
            } else {
                // Code block - preserve whitespace and apply syntax highlighting
                var codeBlock = part.trimmingCharacters(in: .newlines)
                
                // Remove language identifier if present
                if let firstNewline = codeBlock.firstIndex(of: "\n") {
                    let language = codeBlock[..<firstNewline].trimmingCharacters(in: .whitespaces)
                    codeBlock = String(codeBlock[firstNewline...]).trimmingCharacters(in: .newlines)
                    
                    // Apply syntax highlighting based on language
                    if language.lowercased() == "swift" {
                        var codeAttr = formatSwiftCode(codeBlock)
                        let font = NSFont.monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
                        codeAttr.font = .init(font)
                        
                        // Add newlines around code blocks for better spacing
                        result += AttributedString("\n")
                        result += codeAttr
                        result += AttributedString("\n")
                        continue
                    }
                }
                
                // Default formatting for non-Swift or unspecified language
                var codeAttr = AttributedString(codeBlock)
                let font = NSFont.monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
                codeAttr.font = .init(font)
                codeAttr.foregroundColor = Color(nsColor: .labelColor)
                
                // Add newlines around code blocks for better spacing
                result += AttributedString("\n")
                result += codeAttr
                result += AttributedString("\n")
            }
        }
        
        return result
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
                if message.isError {
                    // Error message - always red background with white text
                    VStack(alignment: .trailing, spacing: 0) {
                        Text(message.content)  // No markdown formatting for errors
                            .textSelection(.enabled)
                            .foregroundColor(.white)
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                        
                        copyButton(for: message.content)
                            .padding(.trailing, 3)
                            .padding(.bottom, 3)
                    }
                    .background(Color.red)
                    .cornerRadius(11)
                    .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    // Regular message with markdown formatting
                    VStack(alignment: .trailing, spacing: 0) {
                        Text(formatMarkdown(message.content))
                            .textSelection(.enabled)
                            .foregroundColor(message.isUser ? .white : .primary)
                            .padding(.horizontal)
                            .padding(.top, 4)
                            .padding(.bottom, 7)
                        
                        copyButton(for: message.content)
                            .padding(.trailing, 3)
                            .padding(.bottom, 3)
                    }
                    .background(message.isUser ? Color.blue : Color.black)
                    .cornerRadius(11)
                    .frame(maxWidth: .infinity, alignment: message.isUser ? .trailing : .leading)
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


// Regular Comment
/// Condensed Comment
// MARK: BOLD COMMENT 1
// TODO: BOLD COMMENT 2
func factorial(_ n: Int) -> Int {
    print("The factorial of \(n) is: \(n)")
    
    class test {
        let x = 1
        var y = 2
    }
    if n == 0 {
        return 1
    } else {
        return n * factorial(n - 1)
    }
}









