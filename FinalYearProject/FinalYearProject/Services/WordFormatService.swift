import Foundation

// MARK: - Word Format Service
class WordFormatService: ObservableObject {
    static let shared = WordFormatService()
    
    @Published var isProcessing = false
    @Published var errorMessage = ""
    
    private init() {}
    
    // MARK: - Format as Word Document
    func formatAsWord(_ extractedText: String) async throws -> String {
        guard !extractedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw WordFormatError.emptyText
        }
        
        await MainActor.run {
            isProcessing = true
            errorMessage = ""
        }
        
        defer {
            Task { @MainActor in
                isProcessing = false
            }
        }
        
        // Format the text into professional Word document style
        let formattedDocument = createWordDocument(from: extractedText)
        
        return formattedDocument
    }
    
    // MARK: - Create Word Document Format
    private func createWordDocument(from text: String) -> String {
        let cleanedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check if text already has document structure
        let hasDocStructure = hasDocumentStructure(cleanedText)
        
        if hasDocStructure {
            // Already formatted as document, enhance it
            return enhanceDocument(cleanedText)
        } else {
            // Convert plain text into Word document format
            return convertToDocument(cleanedText)
        }
    }
    
    // MARK: - Check Document Structure
    private func hasDocumentStructure(_ text: String) -> Bool {
        let lowercaseText = text.lowercased()
        
        // Check for common document elements
        let hasTitle = text.split(separator: "\n").first?.count ?? 0 < 100
        let hasParagraphs = text.components(separatedBy: "\n\n").count > 2
        let hasHeadings = lowercaseText.contains("introduction") ||
                         lowercaseText.contains("conclusion") ||
                         lowercaseText.contains("summary") ||
                         lowercaseText.contains("chapter") ||
                         lowercaseText.contains("section")
        
        return hasTitle && (hasParagraphs || hasHeadings)
    }
    
    // MARK: - Enhance Existing Document
    private func enhanceDocument(_ text: String) -> String {
        var enhanced = text
        
        // Ensure proper spacing between sections
        enhanced = enhanced.replacingOccurrences(of: "\n\n\n+", with: "\n\n", options: .regularExpression)
        
        // Add proper paragraph breaks
        enhanced = enhanced.replacingOccurrences(of: "([.!?])([A-Z])", with: "$1\n\n$2", options: .regularExpression)
        
        // Format common section headers
        let sectionHeaders = [
            "Introduction", "Background", "Overview", "Summary",
            "Discussion", "Analysis", "Findings", "Results",
            "Conclusion", "Recommendations", "References"
        ]
        
        for header in sectionHeaders {
            // Make headers stand out
            enhanced = enhanced.replacingOccurrences(
                of: "(?m)^\(header)$",
                with: "\(header.uppercased())",
                options: .regularExpression
            )
        }
        
        return enhanced
    }
    
    // MARK: - Convert Plain Text to Document Format
    private func convertToDocument(_ text: String) -> String {
        var document = ""
        
        // Split into lines
        let lines = text.components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        // Get title (first line or generate one)
        let title = extractTitle(from: lines)
        let contentLines = lines.dropFirst(title == lines.first ? 1 : 0)
        
        // Add title
        document += title.uppercased() + "\n"
        document += String(repeating: "=", count: title.count) + "\n\n"
        
        // Add date and metadata
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        let currentDate = dateFormatter.string(from: Date())
        document += "Date: \(currentDate)\n\n"
        
        // Process content into structured sections
        let sections = organizeSections(from: Array(contentLines))
        
        // Add content sections
        if !sections.isEmpty {
            for (index, section) in sections.enumerated() {
                if index > 0 {
                    document += "\n\n"
                }
                document += formatSection(section, index: index)
            }
        } else {
            // If no clear sections, format as continuous document
            document += formatContinuousContent(Array(contentLines))
        }
        
        // Add footer
        document += "\n\n"
        document += String(repeating: "─", count: 50) + "\n"
        document += "End of Document\n"
        
        return document
    }
    
    // MARK: - Extract Title
    private func extractTitle(from lines: [String]) -> String {
        guard let firstLine = lines.first else {
            return "Untitled Document"
        }
        
        // If first line is short and doesn't end with punctuation, use as title
        if firstLine.count < 100 && !firstLine.hasSuffix(".") && !firstLine.hasSuffix("!") && !firstLine.hasSuffix("?") {
            return firstLine
        }
        
        // Otherwise, extract key words from first sentence
        let words = firstLine.components(separatedBy: " ").prefix(5)
        return words.joined(separator: " ")
    }
    
    // MARK: - Organize Sections
    private func organizeSections(from lines: [String]) -> [[String]] {
        var sections: [[String]] = []
        var currentSection: [String] = []
        
        for line in lines {
            // Check if line is a potential section header
            if isSectionHeader(line) && !currentSection.isEmpty {
                sections.append(currentSection)
                currentSection = [line]
            } else {
                currentSection.append(line)
            }
        }
        
        // Add last section
        if !currentSection.isEmpty {
            sections.append(currentSection)
        }
        
        return sections
    }
    
    // MARK: - Check Section Header
    private func isSectionHeader(_ line: String) -> Bool {
        // Check if line is short and could be a header
        if line.count > 60 {
            return false
        }
        
        let lowercaseLine = line.lowercased()
        let headerKeywords = [
            "introduction", "background", "overview", "summary",
            "chapter", "section", "part", "discussion",
            "analysis", "findings", "results", "conclusion",
            "recommendations", "abstract", "preface"
        ]
        
        return headerKeywords.contains(where: { lowercaseLine.contains($0) })
    }
    
    // MARK: - Format Section
    private func formatSection(_ section: [String], index: Int) -> String {
        guard !section.isEmpty else { return "" }
        
        var formatted = ""
        let header = section.first!
        let content = section.dropFirst()
        
        // Format header
        if isSectionHeader(header) {
            formatted += header.uppercased() + "\n"
            formatted += String(repeating: "─", count: header.count) + "\n\n"
        } else {
            // First section without header, just add content
            formatted += header + "\n\n"
        }
        
        // Format content as paragraphs
        var paragraph = ""
        for line in content {
            if line.count < 50 && line.hasSuffix(":") {
                // Subheading
                if !paragraph.isEmpty {
                    formatted += formatParagraph(paragraph) + "\n\n"
                    paragraph = ""
                }
                formatted += "  " + line + "\n\n"
            } else {
                paragraph += (paragraph.isEmpty ? "" : " ") + line
                
                // End paragraph on sentence-ending punctuation
                if line.hasSuffix(".") || line.hasSuffix("!") || line.hasSuffix("?") {
                    formatted += formatParagraph(paragraph) + "\n\n"
                    paragraph = ""
                }
            }
        }
        
        // Add remaining paragraph
        if !paragraph.isEmpty {
            formatted += formatParagraph(paragraph)
        }
        
        return formatted
    }
    
    // MARK: - Format Continuous Content
    private func formatContinuousContent(_ lines: [String]) -> String {
        var formatted = ""
        var paragraph = ""
        
        for line in lines {
            paragraph += (paragraph.isEmpty ? "" : " ") + line
            
            // End paragraph on sentence-ending punctuation or if paragraph is long
            if (line.hasSuffix(".") || line.hasSuffix("!") || line.hasSuffix("?")) || paragraph.count > 500 {
                formatted += formatParagraph(paragraph) + "\n\n"
                paragraph = ""
            }
        }
        
        // Add remaining content
        if !paragraph.isEmpty {
            formatted += formatParagraph(paragraph)
        }
        
        return formatted
    }
    
    // MARK: - Format Paragraph
    private func formatParagraph(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Add proper indentation and line breaks
        let words = trimmed.components(separatedBy: " ")
        var lines: [String] = []
        var currentLine = "    " // Indent first line
        
        for word in words {
            if currentLine.count + word.count + 1 > 80 {
                lines.append(currentLine)
                currentLine = word
            } else {
                currentLine += (currentLine == "    " ? "" : " ") + word
            }
        }
        
        if !currentLine.isEmpty {
            lines.append(currentLine)
        }
        
        return lines.joined(separator: "\n")
    }
}

// MARK: - Custom Errors
enum WordFormatError: Error, LocalizedError {
    case emptyText
    case invalidFormat
    case processingFailed
    
    var errorDescription: String? {
        switch self {
        case .emptyText:
            return "Please provide text to format"
        case .invalidFormat:
            return "Unable to format as Word document"
        case .processingFailed:
            return "Failed to process Word format"
        }
    }
}

