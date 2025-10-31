import Foundation

// MARK: - Application Format Service
class ApplicationFormatService: ObservableObject {
    static let shared = ApplicationFormatService()
    
    @Published var isProcessing = false
    @Published var errorMessage = ""
    
    private init() {}
    
    // MARK: - Format as Professional Application
    func formatAsApplication(_ extractedText: String) async throws -> String {
        guard !extractedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ApplicationFormatError.emptyText
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
        
        // Auto-format the text into professional application style
        let formattedApplication = createProfessionalFormat(from: extractedText)
        
        return formattedApplication
    }
    
    // MARK: - Create Professional Application Format
    private func createProfessionalFormat(from text: String) -> String {
        let cleanedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check if text already has proper letter structure
        let hasProperStructure = cleanedText.contains("Dear") && 
                                 (cleanedText.contains("Sincerely") || cleanedText.contains("Regards"))
        
        if hasProperStructure {
            // Already formatted properly, just clean it up
            return formatExistingLetter(cleanedText)
        } else {
            // Convert plain text into professional letter format
            return convertToLetterFormat(cleanedText)
        }
    }
    
    // MARK: - Format Existing Letter
    private func formatExistingLetter(_ text: String) -> String {
        var formatted = text
        
        // Ensure proper spacing around sections
        formatted = formatted.replacingOccurrences(of: "\n\n\n+", with: "\n\n", options: .regularExpression)
        
        // Add date if missing
        if !formatted.lowercased().contains(getCurrentMonth()) {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .long
            let date = dateFormatter.string(from: Date())
            
            // Insert date after header section (before Dear)
            if let dearRange = formatted.range(of: "Dear", options: .caseInsensitive) {
                let beforeDear = formatted[..<dearRange.lowerBound]
                let afterDear = formatted[dearRange.lowerBound...]
                formatted = beforeDear + "\n" + date + "\n\n" + afterDear
            }
        }
        
        return formatted
    }
    
    // MARK: - Convert Plain Text to Letter Format
    private func convertToLetterFormat(_ text: String) -> String {
        // Get current date
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        let formattedDate = dateFormatter.string(from: Date())
        
        // Build formatted application
        var application = ""
        
        // Extract header info if present (first few lines)
        var contentStartIndex = 0
        let lines = text.components(separatedBy: "\n").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        
        // Look for contact info in first 5 lines
        var headerLines: [String] = []
        for (index, line) in lines.prefix(5).enumerated() {
            if line.isEmpty { continue }
            
            // Check if line contains contact info
            if line.contains("@") || // email
               line.range(of: "\\d{3}", options: .regularExpression) != nil || // phone
               (index == 0 && line.count < 50 && !line.contains(".")) { // likely name
                headerLines.append(line)
            } else {
                contentStartIndex = index
                break
            }
        }
        
        // Add header
        if !headerLines.isEmpty {
            application += headerLines.joined(separator: "\n") + "\n\n"
        }
        
        // Add date
        application += formattedDate + "\n\n"
        
        // Add salutation if not present
        let mainContent = lines[contentStartIndex...].joined(separator: "\n")
        if !mainContent.lowercased().contains("dear") {
            application += "Dear Hiring Manager,\n\n"
        }
        
        // Add main content
        application += mainContent
        
        // Add closing if not present
        if !mainContent.lowercased().contains("sincerely") && 
           !mainContent.lowercased().contains("regards") {
            application += "\n\nSincerely,\n\n"
            
            // Add name from header if available
            if let firstName = headerLines.first {
                application += firstName
            }
        }
        
        return application
    }
    
    // MARK: - Helper Methods
    private func getCurrentMonth() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM"
        return dateFormatter.string(from: Date()).lowercased()
    }
}

// MARK: - Custom Errors
enum ApplicationFormatError: Error, LocalizedError {
    case emptyText
    case invalidURL
    case invalidResponse
    case apiError(String)
    case formattingFailed
    
    var errorDescription: String? {
        switch self {
        case .emptyText:
            return "Please provide text to format"
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .apiError(let message):
            return "API Error: \(message)"
        case .formattingFailed:
            return "Failed to format application"
        }
    }
}

