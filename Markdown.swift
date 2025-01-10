//
//  Markdown.swift
//  ANIE
//
//  Created by SuperBox64m on 1/10/25.
//

import Foundation

public func formatMarkdown(_ text: String) -> AttributedString {
    // Check if this is an error message
    if text.hasPrefix("Error:") || text.contains("API Error:") {
        var errorAttr = AttributedString(text)
        errorAttr.foregroundColor = .white
        return errorAttr
    }
    
    if var processed = try? AttributedString(markdown: text, options: .init(
        allowsExtendedAttributes: true,
        interpretedSyntax: .inlineOnlyPreservingWhitespace,
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
            processed.replaceSubrange(range, with: AttributedString("• "))
        }
        
        return processed

    }
    
    return AttributedString(text)
}

