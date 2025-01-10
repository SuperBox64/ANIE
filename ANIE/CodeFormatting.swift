import SwiftUI
import AppKit

extension View {
    func formatSwiftCode(_ code: String, colorScheme: ColorScheme) -> AttributedString {
        var result = AttributedString(code)
        
        // Define colors based on color scheme
        let isDarkMode = colorScheme == .dark
        
        // Default text color (white in dark mode, black in light mode)
        let textColor = isDarkMode ? Color.white : Color.black
        
        // Default color is now green (for method calls and properties)
        let defaultColor = isDarkMode ? Color(nsColor: NSColor(red: 108/255, green: 225/255, blue: 133/255, alpha: 1.0)) :
                                      Color(nsColor: NSColor(red: 50/255, green: 144/255, blue: 66/255, alpha: 1.0))
        
        // Define Xcode's syntax highlighting colors
        let keywordColor = isDarkMode ? Color(nsColor: NSColor(red: 255/255, green: 122/255, blue: 178/255, alpha: 1.0)) :
                                      Color(nsColor: NSColor(red: 175/255, green: 35/255, blue: 185/255, alpha: 1.0))     // Pink for keywords
        
        let typeColor = isDarkMode ? Color(nsColor: NSColor(red: 150/255, green: 134/255, blue: 255/255, alpha: 1.0)) :
                                   Color(nsColor: NSColor(red: 76/255, green: 99/255, blue: 175/255, alpha: 1.0))         // Light purple for String
        
        let printColor = isDarkMode ? Color(nsColor: NSColor(red: 202/255, green: 118/255, blue: 255/255, alpha: 1.0)) :
                                    Color(nsColor: NSColor(red: 130/255, green: 45/255, blue: 201/255, alpha: 1.0))       // Darker purple for print
        
        let variableColor = isDarkMode ? Color(nsColor: NSColor(red: 86/255, green: 194/255, blue: 255/255, alpha: 1.0)) :
                                       Color(nsColor: NSColor(red: 11/255, green: 136/255, blue: 186/255, alpha: 1.0))    // Light blue for identifiers
        
        let stringColor = isDarkMode ? Color(nsColor: NSColor(red: 252/255, green: 106/255, blue: 93/255, alpha: 1.0)) :
                                     Color(nsColor: NSColor(red: 196/255, green: 26/255, blue: 22/255, alpha: 1.0))       // Red for strings

        let regularCommentColor = isDarkMode ? Color(nsColor: NSColor(red: 128/255, green: 141/255, blue: 154/255, alpha: 1.0)) :
                                             Color(nsColor: NSColor(red: 93/255, green: 108/255, blue: 121/255, alpha: 1.0))  // Gray for comments
        
        // Set initial color to green
        result.foregroundColor = defaultColor
        
        let text = code as NSString
        let range = NSRange(location: 0, length: text.length)
        
        // 0. Operators and punctuation (default text color)
        let operatorPattern = "[.()\\\\:;,{}]|\\s*[=+\\-*/<>!&|^~]+\\s*"
        if let regex = try? NSRegularExpression(pattern: operatorPattern, options: []) {
            let matches = regex.matches(in: code, range: range)
            for match in matches.reversed() {
                if let stringRange = Range(match.range, in: code),
                   let attributedRange = Range(stringRange, in: result) {
                    var operatorAttr = AttributedString(String(code[stringRange]))
                    operatorAttr.foregroundColor = textColor
                    result.replaceSubrange(attributedRange, with: operatorAttr)
                }
            }
        }
        
        // 1. Keywords (pink)
        let keywords = ["class", "var", "init", "self", "let", "func"]
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

        // 2. Light blue identifiers (all names)
        let bluePatterns = [
            "(?<=\\b(class|var|let|func)\\s+)[a-zA-Z_][a-zA-Z0-9_]*\\b",  // After keywords
            "(?<=\\w+:)\\s*[a-zA-Z_][a-zA-Z0-9_]*(?=\\s*[,)])",          // Parameter values
            "(?<=\\(|,\\s*)[a-zA-Z_][a-zA-Z0-9_]*(?=\\s*:)",             // Parameter names
            "\\b[a-zA-Z_][a-zA-Z0-9_]*(?=\\s*=)",                        // Variables being assigned
            "\\b[a-zA-Z_][a-zA-Z0-9_]*(?=\\s*:)",                        // Variables in declarations
            "\\b[a-zA-Z_][a-zA-Z0-9_]*(?=\\s*\\{)"                       // Class/struct names
        ]
        
        for pattern in bluePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let matches = regex.matches(in: code, range: range)
                for match in matches.reversed() {
                    if let stringRange = Range(match.range, in: code),
                       let attributedRange = Range(stringRange, in: result) {
                        var identifierAttr = AttributedString(String(code[stringRange]))
                        identifierAttr.foregroundColor = variableColor
                        result.replaceSubrange(attributedRange, with: identifierAttr)
                    }
                }
            }
        }

        // 3. Type names (light purple)
        let types = ["String"]
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

        // 4. Print function (dark purple)
        let printPattern = "\\bprint\\b"
        if let regex = try? NSRegularExpression(pattern: printPattern, options: []) {
            let matches = regex.matches(in: code, range: range)
            for match in matches.reversed() {
                if let stringRange = Range(match.range, in: code),
                   let attributedRange = Range(stringRange, in: result) {
                    var printAttr = AttributedString(String(code[stringRange]))
                    printAttr.foregroundColor = printColor
                    result.replaceSubrange(attributedRange, with: printAttr)
                }
            }
        }

        // 5. String literals (orangered)
        let stringPattern = #""[^"\\]*(?:\\.[^"\\]*)*""#
        if let regex = try? NSRegularExpression(pattern: stringPattern, options: []) {
            let matches = regex.matches(in: code, range: range)
            for match in matches.reversed() {
                if let stringRange = Range(match.range, in: code),
                   let attributedRange = Range(stringRange, in: result) {
                    var strAttr = AttributedString(String(code[stringRange]))
                    strAttr.foregroundColor = stringColor
                    result.replaceSubrange(attributedRange, with: strAttr)
                }
            }
        }

        // 6. Comments (gray)
        let commentPattern = "//.*$"
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
}


public func formatMarkdown(_ text: String) -> AttributedString {
    // Check if this is an error message
    if text.hasPrefix("Error:") || text.contains("API Error:") {
        var errorAttr = AttributedString(text)
        errorAttr.foregroundColor = .white
        return errorAttr
    }
    
    if var processed = try? AttributedString(markdown: text, options: .init(
        allowsExtendedAttributes: true,
        interpretedSyntax: .inlineOnly,
        failurePolicy: .returnPartiallyParsedIfPossible
    )) {
        // Process markdown elements
        let headerMarkers = ["#### ", "### ", "## ", "# "]
        for marker in headerMarkers {
            while let range = processed.range(of: marker) {
                processed.replaceSubrange(range, with: AttributedString(""))
            }
        }
        
        // Replace list markers with bullets
        while let range = processed.range(of: "- ") {
            var bulletAttr = AttributedString("• ")
            bulletAttr.font = .systemFont(ofSize: NSFont.systemFontSize + 2)
            processed.replaceSubrange(range, with: bulletAttr)
        }
        
        // Process lines with colons (non-numbered)
        let lines = text.components(separatedBy: .newlines)
        
        // First, handle non-numbered items with colons
        let colonPattern = #"^(?!\s*\d+\.)(.+?):\s*$"#  // Matches lines ending with colon, but not numbered lists
        let colonRegex = try? NSRegularExpression(pattern: colonPattern, options: [.anchorsMatchLines])
        
        for line in lines {
            if let match = colonRegex?.firstMatch(in: line, range: NSRange(location: 0, length: line.utf16.count)),
               let contentRange = Range(match.range(at: 1), in: line) {
                let content = String(line[contentRange])
                if let range = processed.range(of: content + ":") {
                    var headerAttr = AttributedString(content)
                    headerAttr.inlinePresentationIntent = .stronglyEmphasized
                    headerAttr.font = .systemFont(ofSize: NSFont.systemFontSize + 2)
                    processed.replaceSubrange(range, with: headerAttr)
                }
            }
        }
        
        // Then handle numbered lists
        let numberedPattern = #"^\s*\d+\.\s+(.+?)(?::|(?:\s*$))"#  // Match content up to colon or end of line
        let numberedRegex = try? NSRegularExpression(pattern: numberedPattern, options: [.anchorsMatchLines])
        
        for line in lines {
            if let match = numberedRegex?.firstMatch(in: line, range: NSRange(location: 0, length: line.utf16.count)),
               let contentRange = Range(match.range(at: 1), in: line) {
                let content = String(line[contentRange])
                if let range = processed.range(of: content + ":") {
                    // If we found it with the colon, replace it
                    var boldAttr = AttributedString(content)
                    boldAttr.inlinePresentationIntent = .stronglyEmphasized
                    processed.replaceSubrange(range, with: boldAttr)
                } else if let range = processed.range(of: content) {
                    // If we found it without the colon, just make it bold
                    processed[range].inlinePresentationIntent = .stronglyEmphasized
                }
            }
        }
        
        return processed
    }
    
    return AttributedString(text)
}
func extractCodeBlocks(from text: String) -> [(content: String, isCode: Bool)] {
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
