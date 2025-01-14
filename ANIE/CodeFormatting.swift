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
        let typeCyan = Color(nsColor: NSColor(red: 0x27/255, green: 0xf8/255, blue: 0xff/255, alpha: 1.0))       // #27f8ff - Student type
        let funcMagenta = Color(nsColor: NSColor(red: 0xd8/255, green: 0x4d/255, blue: 0xbf/255, alpha: 1.0))    // #d84dbf - print/append/forEach
        let methodPurple = Color(nsColor: NSColor(red: 0xc0/255, green: 0x8a/255, blue: 0xff/255, alpha: 1.0))   // #c08aff - isEmpty/count
        let numberYellow = Color(nsColor: NSColor(red: 0xd0/255, green: 0xbc/255, blue: 0x56/255, alpha: 1.0))   // #d0bc56 - numbers
        let stringOrange = Color(nsColor: NSColor(red: 0xfd/255, green: 0x9f/255, blue: 0x39/255, alpha: 1.0))   // #fd9f39 - String type
        let methodGreen = Color(nsColor: NSColor(red: 0x98/255, green: 0xff/255, blue: 0xb3/255, alpha: 1.0))      // #98ffb3 - method calls
        
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
            applyColor(regex, methodGreen)
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
     
    
  if !searchTerm.isEmpty {
            // Add search term highlighting at the end
            applySearchHighlighting(to: &result, searchTerm: searchTerm, originalText: code, isCurrentSearchResult: isCurrentSearchResult)
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
    // 1. Create initial AttributedString
    var attributedResult = AttributedString(text)
    
    // 2. Apply markdown formatting to AttributedString
    
    // Headers
    if let regex = try? NSRegularExpression(pattern: "^(#{1,6})\\s+(.+?)\\s*$", options: [.anchorsMatchLines]) {
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: text.utf16.count))
        for match in matches {
            if let headerRange = Range(match.range(at: 2), in: text),
               let attributedRange = Range(headerRange, in: attributedResult) {
                attributedResult[attributedRange].inlinePresentationIntent = .stronglyEmphasized
            }
        }
    }
    
    // // Links
    // if let regex = try? NSRegularExpression(pattern: "\\[([^\\]]+)\\]\\(([^\\)]+)\\)", options: []) {
    //     let matches = regex.matches(in: text, range: NSRange(location: 0, length: text.utf16.count))
    //     for match in matches {
    //         if let textRange = Range(match.range(at: 1), in: text),
    //            let urlRange = Range(match.range(at: 2), in: text),
    //            let attributedRange = Range(textRange, in: attributedResult) {
    //             let url = String(text[urlRange])
    //             attributedResult[attributedRange].link = URL(string: url)
    //             attributedResult[attributedRange].foregroundColor = .blue
    //             attributedResult[attributedRange].underlineStyle = .single
    //         }
    //     }
    // }
    
    // Bold and Italic
    if let regex = try? NSRegularExpression(pattern: "(\\*\\*\\*|___)(.+?)\\1", options: []) {
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: text.utf16.count))
        for match in matches {
            if let boldItalicRange = Range(match.range(at: 2), in: text),
               let attributedRange = Range(boldItalicRange, in: attributedResult) {
                attributedResult[attributedRange].inlinePresentationIntent = [.stronglyEmphasized, .emphasized]
            }
        }
    }
    
    // Bold
    if let regex = try? NSRegularExpression(pattern: "(\\*\\*|__)(.+?)\\1", options: []) {
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: text.utf16.count))
        for match in matches {
            if let boldRange = Range(match.range(at: 2), in: text),
               let attributedRange = Range(boldRange, in: attributedResult) {
                attributedResult[attributedRange].inlinePresentationIntent = .stronglyEmphasized
            }
        }
    }
   
    
    // Italic
    if let regex = try? NSRegularExpression(pattern: "(?<!\\*|_)(\\*|_)(?!\\*|_)(.+?)\\1(?!\\*|_)", options: []) {
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: text.utf16.count))
        for match in matches {
            if let italicRange = Range(match.range(at: 2), in: text),
               let attributedRange = Range(italicRange, in: attributedResult) {
                attributedResult[attributedRange].inlinePresentationIntent = .emphasized
            }
        }
    }
    
    // // Inline code
    // if let regex = try? NSRegularExpression(pattern: "`([^`]+)`", options: []) {
    //     let matches = regex.matches(in: text, range: NSRange(location: 0, length: text.utf16.count))
    //     for match in matches.reversed() {
    //         if let fullRange = Range(match.range, in: attributedResult) {
    //             var codeText = attributedResult[fullRange]
    //             //codeText.inlinePresentationIntent = .code
    //             //codeText.backgroundColor = Color.black.opacity(0.5)
    //             codeText.font = .init(name: "Courier Bold", size: NSFont.systemFontSize)
    //             // Remove the backticks
    //             if let start = codeText.characters.index(codeText.startIndex, offsetBy: 1, limitedBy: codeText.endIndex),
    //                let end = codeText.characters.index(codeText.endIndex, offsetBy: -1, limitedBy: codeText.startIndex) {
    //                 codeText = codeText[start..<end]
    //             }
    //             attributedResult.replaceSubrange(fullRange, with: codeText)
    //         }
    //     }
    // }

    //Process markdown elements
    let markers = ["###### ", "##### ", "#### ", "### ", "## ", "# ", "`", "***", "**","*"]
    for marker in markers {
        if let regex = try? NSRegularExpression(pattern: NSRegularExpression.escapedPattern(for: marker), options: []) {
            let matches = regex.matches(in: text, range: NSRange(location: 0, length: text.utf16.count))
            for match in matches.reversed() {
                if let range = Range(match.range, in: attributedResult) {
                    var invisible = AttributedString(marker)
                    invisible.foregroundColor = .clear
                    invisible.font = .systemFont(ofSize: 0.1)
                    attributedResult.replaceSubrange(range, with: invisible)
                }
            }
        }
    }

    // let replaceMarkers = ["- "]
    // for marker in replaceMarkers {
    //     while let range = attributedResult.range(of: marker) {
    //         var bulletPoint = AttributedString("• ")
    //         bulletPoint.inlinePresentationIntent = .stronglyEmphasized
    //         bulletPoint.font = .boldSystemFont(ofSize: NSFont.systemFontSize + 2.5)
    //         attributedResult.replaceSubrange(range, with: bulletPoint)
    //     }
    // }

  
    // Add search term highlighting at the end
    applySearchHighlighting(to: &attributedResult, searchTerm: searchTerm, originalText: text, isCurrentSearchResult: isCurrentSearchResult)
    
    return attributedResult
}

private func applySearchHighlighting(to attributedString: inout AttributedString, searchTerm: String, originalText: String, isCurrentSearchResult: Bool = false) {
    if !searchTerm.isEmpty {
        let searchTerms = searchTerm.split(separator: " ")
            .map(String.init)
            .filter { !$0.isEmpty }
        
        // Collect all matches first
        var allMatches: [(Range<String.Index>, String)] = []
        
        for term in searchTerms {
            let pattern = NSRegularExpression.escapedPattern(for: term)
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
                let matches = regex.matches(in: originalText, range: NSRange(location: 0, length: originalText.utf16.count))
                for match in matches {
                    if let range = Range(match.range, in: originalText) {
                        allMatches.append((range, term))
                    }
                }
            }
        }
        
        // Sort matches by location (in reverse order to not invalidate ranges)
        allMatches.sort { $0.0.lowerBound > $1.0.lowerBound }
        
        // Apply all highlights in reverse order
        for (range, _) in allMatches {
            if let attributedRange = Range(range, in: attributedString) {
                var highlightedText = attributedString[attributedRange]
                if isCurrentSearchResult {
                    highlightedText.backgroundColor = Color(nsColor: NSColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 0.3))
                } else {
                    highlightedText.backgroundColor = Color(nsColor: NSColor(red: 1.0, green: 1.0, blue: 0.0, alpha: 0.3))
                }
                attributedString.replaceSubrange(attributedRange, with: highlightedText)
            }
        }
    }
}

