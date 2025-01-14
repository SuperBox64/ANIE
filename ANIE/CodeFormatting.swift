import SwiftUI
import AppKit

extension View {
    func formatSwiftCode(_ code: String, colorScheme: ColorScheme, searchTerm: String = "", isCurrentSearchResult: Bool = false) -> AttributedString {
        var result = AttributedString(code)
        
        let text = code as NSString
        let range = NSRange(location: 0, length: text.length)
        
        // Colors from HTML with exact hex values
        let defaultColor = Color(nsColor: NSColor(red: 0xd0/255, green: 0xe8/255, blue: 0xdc/255, alpha: 1.0))   // #d0e8dc - default text
        let keywordPink = Color(nsColor: NSColor(red: 0xff/255, green: 0x60/255, blue: 0x70/255, alpha: 1.0))    // #ff6070 - keywords (bold)
        let commentGray = Color(nsColor: NSColor(red: 0x75/255, green: 0x89/255, blue: 0x92/255, alpha: 1.0))    // #758992 - comments
        let classGreen = Color(nsColor: NSColor(red: 0x89/255, green: 0xff/255, blue: 0x2b/255, alpha: 1.0))     // #89ff2b - class names
        let varBlue = Color(nsColor: NSColor(red: 0x60/255, green: 0xa5/255, blue: 0xff/255, alpha: 1.0))        // #60a5ff - variables/functions
        let typeOrange = Color(nsColor: NSColor(red: 0xfd/255, green: 0x97/255, blue: 0x09/255, alpha: 1.0))     // #fd9709 - Int/Double/Float
        let propGreen = Color(nsColor: NSColor(red: 0x30/255, green: 0xd0/255, blue: 0x40/255, alpha: 1.0))      // #30d040 - property access
        let methodGreen = Color(nsColor: NSColor(red: 0x49/255, green: 0xc1/255, blue: 0x75/255, alpha: 1.0))    // #49c175 - method calls
        let typeCyan = Color(nsColor: NSColor(red: 0x27/255, green: 0xf8/255, blue: 0xff/255, alpha: 1.0))       // #27f8ff - Student type
        let funcMagenta = Color(nsColor: NSColor(red: 0xd8/255, green: 0x4d/255, blue: 0xbf/255, alpha: 1.0))    // #d84dbf - print/append/forEach
        let methodPurple = Color(nsColor: NSColor(red: 0xc0/255, green: 0x8a/255, blue: 0xff/255, alpha: 1.0))   // #c08aff - isEmpty/count
        let numberYellow = Color(nsColor: NSColor(red: 0xd0/255, green: 0xbc/255, blue: 0x56/255, alpha: 1.0))   // #d0bc56 - numbers
        let stringOrange = Color(nsColor: NSColor(red: 0xfd/255, green: 0x9f/255, blue: 0x39/255, alpha: 1.0))   // #fd9f39 - String type
        let mintGreen = Color(nsColor: NSColor(red: 0x98/255, green: 0xff/255, blue: 0xb3/255, alpha: 1.0))      // #98ffb3 - method calls
        
        func applyColor(_ regex: NSRegularExpression, _ color: Color, bold: Bool = false) {
            let matches = regex.matches(in: code, range: range)
            for match in matches.reversed() {
                if let stringRange = Range(match.range, in: code),
                   let attributedRange = Range(stringRange, in: result) {
                    var attr = AttributedString(String(code[stringRange]))
                    attr.foregroundColor = color
                    if bold {
                        attr.font = .boldSystemFont(ofSize: NSFont.systemFontSize)
                    }
                    result.replaceSubrange(attributedRange, with: attr)
                }
            }
        }
        

        // Color variable names after let/var blue
        if let regex = try? NSRegularExpression(pattern: "(?<=\\b(?:let|var)\\s+)[a-zA-Z_][a-zA-Z0-9_]*(?=\\s*=)", options: []) {
            applyColor(regex, varBlue)
        }

        // Color function names and parameter labels mint green
        if let regex = try? NSRegularExpression(pattern: "[a-zA-Z_][a-zA-Z0-9_]*(?=\\s*\\()|[a-zA-Z_][a-zA-Z0-9_]*(?=\\s*:)", options: []) {
            applyColor(regex, mintGreen)
        }

        // Color function arguments green
        if let regex = try? NSRegularExpression(pattern: "(?<=:\\s*)[a-zA-Z_][a-zA-Z0-9_]*(?=\\s*\\)?)", options: []) {
            applyColor(regex, propGreen)
        }
        
        // Color class/struct names lime green
        if let regex = try? NSRegularExpression(pattern: "(?<=\\b(?:class|struct)\\s)[A-Z][a-zA-Z0-9_]*(?=\\s*\\{)", options: []) {
            applyColor(regex, classGreen)
        }
        
        // Combined pattern for typeCyan
        if let regex = try? NSRegularExpression(pattern: "\\b[A-Z][a-zA-Z0-9_]*\\b(?!\\s*\\{)|(?<=\\[)[A-Z][a-zA-Z0-9_]*(?=\\])", options: []) {
            applyColor(regex, typeCyan)
        }
        
        // Color Swift types orange
        if let regex = try? NSRegularExpression(pattern: "\\b(String|Int|Double)\\b", options: []) {
            applyColor(regex, typeOrange)
        }
        
        // Combined pattern for all blue coloring
        if let regex = try? NSRegularExpression(pattern: "(?:(?<=\\b(?:let|var)\\s)[^=:]+(?=\\s*[=:])|(?<=func\\s)[a-zA-Z_][a-zA-Z0-9_]*(?=\\s*\\()|[a-zA-Z_][a-zA-Z0-9_]*(?=\\s*:)|_(?=[a-zA-Z]))", options: []) {
            applyColor(regex, varBlue)
        }

        // Combined pattern for all property green coloring
        if let regex = try? NSRegularExpression(pattern: "(?:(?<=self\\.)|(?<=\\\\\\())[a-zA-Z_][a-zA-Z0-9_\\.]*(?=\\)|\\s|$)|[a-zA-Z_][a-zA-Z0-9_]*(?=\\.(?:append|isEmpty|count|forEach|contains|[a-zA-Z_][a-zA-Z0-9_]*\\())|(?<=\\()[a-zA-Z_][a-zA-Z0-9_]*(?=\\))", options: []) {
            applyColor(regex, propGreen)
        }

        // Color numeric literals yellow
        if let regex = try? NSRegularExpression(pattern: "\\b\\d+(?:\\.\\d+)?\\b", options: []) {
            applyColor(regex, numberYellow)
        }

        // Combined pattern for methodPurple
        if let regex = try? NSRegularExpression(pattern: "\\.(?:append|isEmpty|count|forEach)\\b", options: []) {
            applyColor(regex, methodPurple)
        }

        // Color print keyword purple
        if let regex = try? NSRegularExpression(pattern: "\\bprint\\b|\\bmax\\b", options: []) {
            applyColor(regex, funcMagenta)
        }

        // Color variable properties green when after let/var at line start
        if let regex = try? NSRegularExpression(pattern: "(?<=^\\s*(?:let|var)\\s+[^=:]+:\\s*)[a-zA-Z_][a-zA-Z0-9_]*(?=\\s*[=,])", options: [.anchorsMatchLines]) {
            applyColor(regex, propGreen)
        }

        // Color parameter labels and arguments in function calls green
        if let regex = try? NSRegularExpression(pattern: "[a-zA-Z_][a-zA-Z0-9_]*(?=\\s*:)|(?<=:\\s*)[a-zA-Z_][a-zA-Z0-9_]*(?=\\s*\\)?)", options: []) {
            applyColor(regex, propGreen)
        }
        
        // Color array names after 'in' in green
        if let regex = try? NSRegularExpression(pattern: "(?<=\\sin\\s)[a-zA-Z_][a-zA-Z0-9_]*(?=\\s*\\{)", options: []) {
            applyColor(regex, propGreen)
        }
        
        // Color variables before += in green
        if let regex = try? NSRegularExpression(pattern: "\\b[a-zA-Z_][a-zA-Z0-9_]*\\b(?=\\s*\\+=)", options: []) {
            applyColor(regex, propGreen)
        }
        
        // Color variables after += in green
        if let regex = try? NSRegularExpression(pattern: "(?<=\\+=)\\s*[a-zA-Z_][a-zA-Z0-9_]*", options: []) {
            applyColor(regex, propGreen)
        }
        
        // Color variables after return in green
        if let regex = try? NSRegularExpression(pattern: "[a-zA-Z_][a-zA-Z0-9_]*(?=\\s*(?://|$))", options: []) {
            applyColor(regex, propGreen)
        }

        // Color text after import white (moved to end)
        if let regex = try? NSRegularExpression(pattern: "(?<=import\\s)[^\\n]+", options: []) {
            applyColor(regex, defaultColor)
        }

        // Color string contents orange (excluding interpolation)
        if let regex = try? NSRegularExpression(pattern: "\"[^\"\\\\]*(?:\\\\.[^\"\\\\]*)*\"", options: []) {
            applyColor(regex, stringOrange)
        }
        
         // Combined pattern for methodPurple
        if let regex = try? NSRegularExpression(pattern: "\\.(?:reduce)\\b", options: []) {
            applyColor(regex, defaultColor)
        }

        // Color Swift keywords pink
        if let regex = try? NSRegularExpression(pattern: "\\b(import|mutating|class|let|var|init|func|return|self|struct|in|for)\\b", options: []) {
            applyColor(regex, keywordPink, bold: true)
        }
        

        // Color string interpolation delimiters default color
        if let regex = try? NSRegularExpression(pattern: "\\\\\\(|\\)", options: []) {
            applyColor(regex, defaultColor)
        }
        
            // Color variables inside string interpolation green
        if let regex = try? NSRegularExpression(pattern: "(?<=\\\\\\()[a-zA-Z_][a-zA-Z0-9_]*(?=\\))", options: []) {
            applyColor(regex, propGreen)
        }
        
        // Color comments gray
        if let regex = try? NSRegularExpression(pattern: "//.*$", options: [.anchorsMatchLines]) {
            applyColor(regex, commentGray)
        }

        // Color MARK/TODO comments bold gray
        if let regex = try? NSRegularExpression(pattern: "//\\s*(?:MARK:|TODO:).*$", options: [.anchorsMatchLines]) {
            applyColor(regex, commentGray, bold: true)
        }

        // Color parameter names after underscore in default color
        if let regex = try? NSRegularExpression(pattern: "(?<=_\\s)[a-zA-Z_][a-zA-Z0-9_]*(?=\\s*:)", options: []) {
            applyColor(regex, defaultColor)
        }
     
    

        // Add search term highlighting at the end
        if !searchTerm.isEmpty {
            let searchTermLowercased = searchTerm.lowercased()
            let textLowercased = code.lowercased()
            
            if let range = textLowercased.range(of: searchTermLowercased),
               let attributedRange = Range(range, in: result) {
                var highlightedText = result[attributedRange]
                highlightedText.backgroundColor = .yellow
                highlightedText.foregroundColor = .black
                highlightedText.inlinePresentationIntent = .stronglyEmphasized
                result.replaceSubrange(attributedRange, with: highlightedText)
            }
        }

        return result
    }
}

public func extractCodeBlocks(from text: String) -> [(content: String, isCode: Bool)] {
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

public func formatMarkdown(_ text: String, colorScheme: ColorScheme = .dark, searchTerm: String = "", isCurrentSearchResult: Bool = false) -> AttributedString {
    // First, split the text into lines while preserving empty lines
    let lines = text.components(separatedBy: CharacterSet.newlines)
    var processedLines: [String] = []
    
    // Process each line individually to preserve whitespace
    for line in lines {
        var processedLine = line
        
        // Headers - remove ### completely, starting with longest match
        let headerPrefixes = ["#### ", "### ", "## ", "# "]
        for prefix in headerPrefixes {
            if processedLine.hasPrefix(prefix) {
                processedLine = String(processedLine.dropFirst(prefix.count))
                break
            }
        }
        
       
        
        // Bold and Italic - remove *** or ___ while preserving inner whitespace
        while let range = processedLine.range(of: "(\\*\\*\\*|___)(.+?)\\1", options: .regularExpression) {
            let matched = processedLine[range]
            let content = String(matched.dropFirst(3).dropLast(3))
            processedLine.replaceSubrange(range, with: content)
        }
        
        // Bold - remove ** or __ while preserving inner whitespace
        while let range = processedLine.range(of: "(\\*\\*|__)(.+?)\\1", options: .regularExpression) {
            let matched = processedLine[range]
            let content = String(matched.dropFirst(2).dropLast(2))
            processedLine.replaceSubrange(range, with: content)
        }
        
        // Italic - remove * or _ while preserving inner whitespace
        while let range = processedLine.range(of: "(?<!\\*|_)(\\*|_)(?!\\*|_)(.+?)\\1(?!\\*|_)", options: .regularExpression) {
            let matched = processedLine[range]
            let content = String(matched.dropFirst(1).dropLast(1))
            processedLine.replaceSubrange(range, with: content)
        }
        
        // Links - extract link text and URL
        while let range = processedLine.range(of: "\\[([^\\]]+)\\]\\(([^\\)]+)\\)", options: .regularExpression) {
            let matched = processedLine[range]
            let content = String(matched)
            let linkPattern = "\\[([^\\]]+)\\]\\(([^\\)]+)\\)"
            if let regex = try? NSRegularExpression(pattern: linkPattern),
               let match = regex.firstMatch(in: content, range: NSRange(content.startIndex..., in: content)) {
                if let textRange = Range(match.range(at: 1), in: content) {
                    let linkText = String(content[textRange])
                    processedLine.replaceSubrange(range, with: linkText)
                }
            }
        }
        
        // Remove ! marker at the beginning of the line
        if processedLine.hasPrefix("!") {
            processedLine.removeFirst()
        }
    
        // Lists - replace dash with bullet while preserving indentation
        if let range = processedLine.range(of: "^(\\s*)[•-]\\s", options: .regularExpression) {
            let indentation = processedLine[..<range.upperBound].prefix(while: { $0.isWhitespace })
            let content = String(processedLine[range.upperBound...])
            processedLine = indentation + "• " + content
        }
        
//           // Remove backticks while preserving the text inside
//        while let range = processedLine.range(of: "`([^`]+)`", options: .regularExpression) {
//            let matched = processedLine[range]
//            let content = String(matched.dropFirst().dropLast())
//            processedLine.replaceSubrange(range, with: content)
//        }
        

        processedLines.append(processedLine)
    }
    
    // Rejoin lines preserving all line endings
    let result = processedLines.joined(separator: "\n")
    
    // Create attributed string
    var attributedResult = AttributedString(result)
    
    // Apply styles based on original markdown
    // Headers
    if let regex = try? NSRegularExpression(pattern: "^(?:#{1,6}\\s+)(.+?)\\s*$", options: [.anchorsMatchLines]) {
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: text.utf16.count))
        for match in matches {
            if let headerRange = Range(match.range(at: 1), in: text),
               let contentRange = result.range(of: String(text[headerRange])),
               let attributedRange = Range(contentRange, in: attributedResult) {
                attributedResult[attributedRange].inlinePresentationIntent = .stronglyEmphasized
            }
        }
    }
    
    // Links
    if let regex = try? NSRegularExpression(pattern: "\\[([^\\]]+)\\]\\(([^\\)]+)\\)", options: []) {
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: text.utf16.count))
        for match in matches {
            if let textRange = Range(match.range(at: 1), in: text),
               let urlRange = Range(match.range(at: 2), in: text),
               let contentRange = result.range(of: String(text[textRange])),
               let attributedRange = Range(contentRange, in: attributedResult) {
                let url = String(text[urlRange])
                attributedResult[attributedRange].link = URL(string: url)
                attributedResult[attributedRange].foregroundColor = .blue
                attributedResult[attributedRange].underlineStyle = .single
            }
        }
    }
    
    // Code blocks - only process text wrapped in backticks
    if let regex = try? NSRegularExpression(pattern: "`[^`]+`", options: []) {
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: text.utf16.count))
        for match in matches {
            if let fullRange = Range(match.range, in: text) {
                let fullText = String(text[fullRange])
                let codeText = String(fullText.dropFirst().dropLast())  // Remove backticks
                // Search for this text in our attributed string
                if let range = attributedResult.range(of: codeText) {
                    var codeAttr = AttributedString(codeText)
                    codeAttr.inlinePresentationIntent = .code
                    codeAttr.backgroundColor = Color.black.opacity(0.225)
                    attributedResult.replaceSubrange(range, with: codeAttr)
                }
            }
        }
    }
    
    // Bold and Italic text
    if let regex = try? NSRegularExpression(pattern: "(\\*\\*\\*|___)(.+?)\\1", options: []) {
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: text.utf16.count))
        for match in matches {
            if let boldItalicRange = Range(match.range(at: 2), in: text),
               let contentRange = result.range(of: String(text[boldItalicRange])),
               let attributedRange = Range(contentRange, in: attributedResult) {
                attributedResult[attributedRange].inlinePresentationIntent = [.stronglyEmphasized, .emphasized]
            }
        }
    }
    
    // Bold text
    if let regex = try? NSRegularExpression(pattern: "(\\*\\*|__)(.+?)\\1", options: []) {
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: text.utf16.count))
        for match in matches {
            if let boldRange = Range(match.range(at: 2), in: text),
               let contentRange = result.range(of: String(text[boldRange])),
               let attributedRange = Range(contentRange, in: attributedResult) {
                attributedResult[attributedRange].inlinePresentationIntent = .stronglyEmphasized
            }
        }
    }
    
    // Italic text
    if let regex = try? NSRegularExpression(pattern: "(?<!\\*|_)(\\*|_)(?!\\*|_)(.+?)\\1(?!\\*|_)", options: []) {
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: text.utf16.count))
        for match in matches {
            if let italicRange = Range(match.range(at: 2), in: text),
               let contentRange = result.range(of: String(text[italicRange])),
               let attributedRange = Range(contentRange, in: attributedResult) {
                attributedResult[attributedRange].inlinePresentationIntent = .emphasized
            }
        }
    }
    
    // Add search term highlighting at the end
    if !searchTerm.isEmpty {
        let searchTerms = searchTerm.split(separator: " ")
            .map(String.init)
            .filter { !$0.isEmpty }
        let textLowercased = result.lowercased()
        
        var allMatches: [(Range<String.Index>, String)] = []
        for term in searchTerms {
            let termLowercased = term.lowercased()
            let pattern = NSRegularExpression.escapedPattern(for: termLowercased)
            
            if let regex = try? NSRegularExpression(pattern: pattern) {
                let matches = regex.matches(in: textLowercased, range: NSRange(location: 0, length: textLowercased.utf16.count))
                for match in matches {
                    if let range = Range(match.range, in: textLowercased) {
                        allMatches.append((range, term))
                    }
                }
            }
        }
        
        allMatches.sort { $0.0.lowerBound > $1.0.lowerBound }
        
        for (range, _) in allMatches {
            if let attributedRange = Range(range, in: attributedResult) {
                var highlightedText = attributedResult[attributedRange]
                highlightedText.backgroundColor = Color.yellow
                highlightedText.foregroundColor = Color.black
                highlightedText.inlinePresentationIntent = .stronglyEmphasized
                attributedResult.replaceSubrange(attributedRange, with: highlightedText)
            }
        }
    }
    
    return attributedResult
} 
