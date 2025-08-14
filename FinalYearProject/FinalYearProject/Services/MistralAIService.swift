import Foundation
import UIKit

// MARK: - Timeout Helper
func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask {
            try await operation()
        }
        
        group.addTask {
            try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            throw MistralAIError.timeout
        }
        
        let result = try await group.next()!
        group.cancelAll()
        return result
    }
}

// MARK: - Models
struct OCRResponse: Codable {
    let pages: [OCRPage]
    let usage_info: UsageInfo?
}

struct OCRPage: Codable {
    let index: Int
    let markdown: String
    let images: [OCRImage]?
    let dimensions: PageDimensions?
}

struct OCRImage: Codable {
    let id: String
    let image_annotation: String?
}

struct PageDimensions: Codable {
    let dpi: Int
    let height: Int
    let width: Int
}

struct UsageInfo: Codable {
    let pages_processed: Int
    let doc_size_bytes: Int
}

// MARK: - API Service
class MistralAIService: ObservableObject {
    static let shared = MistralAIService()
    
    // Using secure API configuration
    private let apiKey = APIKeys.mistralAIKey
    private let baseURL = APIKeys.mistralAIBaseURL
    
    @Published var isProcessing = false
    @Published var extractedText = ""
    @Published var errorMessage = ""
    
    private init() {}
    
    private func cleanMarkdownText(_ markdown: String) -> String {
        var cleaned = markdown
        
        // First, check if the entire content is just an image reference
        let imageOnlyPattern = #"^#?\s*!\[.*?\]\(.*?\)\s*$"#
        if cleaned.range(of: imageOnlyPattern, options: .regularExpression) != nil {
            // This is just an image reference with no actual text
            return ""
        }
        
        // Remove markdown headers with image references
        cleaned = cleaned.replacingOccurrences(
            of: #"#\s*!\[.*?\]\(.*?\)"#,
            with: "",
            options: .regularExpression
        )
        
        // Remove standalone image references
        cleaned = cleaned.replacingOccurrences(
            of: #"!\[.*?\]\(.*?\)"#,
            with: "",
            options: .regularExpression
        )
        
        // Remove any remaining image file references
        cleaned = cleaned.replacingOccurrences(
            of: #"img-\d+\.\w+"#,
            with: "",
            options: .regularExpression
        )
        
        // Remove standalone # symbols at the beginning of lines
        cleaned = cleaned.replacingOccurrences(
            of: #"^#\s*$"#,
            with: "",
            options: .regularExpression
        )
        
        // Clean up extra whitespace and empty lines
        let lines = cleaned.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        cleaned = lines.joined(separator: "\n")
        
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - OCR Text Extraction
    func extractTextFromImage(_ image: UIImage) async throws -> String {
        // Convert image to base64
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw MistralAIError.imageConversionFailed
        }
        
        let base64String = imageData.base64EncodedString()
        
        // Prepare request
        guard let url = URL(string: baseURL) else {
            throw MistralAIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60.0  // Increased timeout to 60 seconds
        
        // Create request body - DON'T include include_image_base64
        let requestBody: [String: Any] = [
            "model": "mistral-ocr-latest",
            "document": [
                "type": "image_url",
                "image_url": "data:image/jpeg;base64,\(base64String)"
            ]
            // Removed include_image_base64 to get text instead of image reference
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            
            // Make API call with timeout handling
            let (data, response) = try await withTimeout(seconds: 60) {
                try await URLSession.shared.data(for: request)
            }
            
            // Check response status
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode != 200 {
                    // Print error response for debugging
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("API Error Response: \(responseString)")
                    }
                    throw MistralAIError.apiError("Status \(httpResponse.statusCode)")
                }
            }
            
            // Print response for debugging
            if let responseString = String(data: data, encoding: .utf8) {
                print("API Response: \(responseString)")
            }
            
            // Parse response
            let ocrResponse = try JSONDecoder().decode(OCRResponse.self, from: data)
            
            // Check if there are any pages
            guard let firstPage = ocrResponse.pages.first else {
                return "No pages found in the document"
            }
            
            // Get the markdown content
            let rawMarkdown = firstPage.markdown
            
            // Check if there's an image annotation that might contain text
            if let images = firstPage.images,
               let firstImage = images.first,
               let annotation = firstImage.image_annotation,
               !annotation.isEmpty {
                // Use the annotation if available
                return annotation
            }
            
            // Clean the markdown to remove image references
            let cleanedText = self.cleanMarkdownText(rawMarkdown)
            
            // If no text was found after cleaning, the image might not contain text
            if cleanedText.isEmpty {
                // Check if this was just an image with no text
                if rawMarkdown.contains("![") && rawMarkdown.contains("](") {
                    return "The image was processed but no text was detected. The image might contain only graphics or the text might not be readable."
                }
                return "No readable text found in the image"
            }
            
            return cleanedText
            
        } catch let decodingError as DecodingError {
            print("Decoding error: \(decodingError)")
            throw MistralAIError.apiError("Failed to parse response: \(decodingError.localizedDescription)")
        } catch {
            throw MistralAIError.apiError(error.localizedDescription)
        }
    }
    
    // MARK: - Alternative extraction method using raw response
    func extractTextFromImageAlternative(_ image: UIImage) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw MistralAIError.imageConversionFailed
        }
        
        let base64String = imageData.base64EncodedString()
        
        guard let url = URL(string: baseURL) else {
            throw MistralAIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Try without any extra parameters
        let requestBody: [String: Any] = [
            "model": "mistral-ocr-latest",
            "document": [
                "type": "image_url",
                "image_url": "data:image/jpeg;base64,\(base64String)"
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw MistralAIError.apiError("Request failed")
        }
        
        // Parse as dictionary to check all fields
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
            print("Full JSON response: \(json)")
            
            // Look for text in various possible locations
            if let pages = json["pages"] as? [[String: Any]],
               let firstPage = pages.first {
                
                // Check different possible text fields
                let possibleTextFields = ["text", "content", "extracted_text", "ocr_text", "result"]
                
                for field in possibleTextFields {
                    if let text = firstPage[field] as? String, !text.isEmpty {
                        print("Found text in field '\(field)': \(text)")
                        return text
                    }
                }
                
                // Check markdown field but look for actual text
                if let markdown = firstPage["markdown"] as? String {
                    let cleaned = cleanMarkdownText(markdown)
                    if !cleaned.isEmpty {
                        return cleaned
                    }
                }
            }
        }
        
        return "No text could be extracted from the image"
    }
    
    // MARK: - Text Processing
    func processExtractedText(_ text: String) -> String {
        // Clean up the extracted text
        var processedText = text
        
        // Remove extra whitespace
        processedText = processedText.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        
        // Remove empty lines
        processedText = processedText.components(separatedBy: .newlines)
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .joined(separator: "\n")
        
        return processedText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Custom Errors
enum MistralAIError: Error, LocalizedError {
    case imageConversionFailed
    case noTextFound
    case apiError(String)
    case invalidURL
    case timeout
    
    var errorDescription: String? {
        switch self {
        case .imageConversionFailed:
            return "Failed to convert image to base64"
        case .noTextFound:
            return "No text found in the image"
        case .apiError(let message):
            return "API Error: \(message)"
        case .invalidURL:
            return "Invalid API URL"
        case .timeout:
            return "Request timed out. Please try again with a smaller image or check your internet connection."
        }
    }
}
