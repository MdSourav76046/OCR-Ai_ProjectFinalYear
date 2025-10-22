import Foundation

// MARK: - Models
struct GrammarCorrectionRequest: Codable {
    let data: String
}

struct GrammarCorrectionResponse: Codable {
    let data: [String]
}

// MARK: - Grammar Correction Service
class GrammarCorrectionService: ObservableObject {
    static let shared = GrammarCorrectionService()
    
    private let apiURL = APIKeys.huggingFaceAPIURL
    
    @Published var isProcessing = false
    @Published var errorMessage = ""
    
    private init() {}
    
    // MARK: - Grammar Correction
    func correctGrammar(_ text: String) async throws -> String {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw GrammarCorrectionError.emptyText
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
        
        // Prepare request
        guard let url = URL(string: apiURL) else {
            throw GrammarCorrectionError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30.0
        
        // Create request body
        let requestBody = GrammarCorrectionRequest(data: text)
        
        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
            
            // Make API call
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Check response status
            guard let httpResponse = response as? HTTPURLResponse else {
                throw GrammarCorrectionError.invalidResponse
            }
            
            if httpResponse.statusCode != 200 {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw GrammarCorrectionError.apiError("Status \(httpResponse.statusCode): \(errorMessage)")
            }
            
            // Parse response
            let correctionResponse = try JSONDecoder().decode(GrammarCorrectionResponse.self, from: data)
            
            guard let correctedText = correctionResponse.data.first, !correctedText.isEmpty else {
                throw GrammarCorrectionError.noCorrection
            }
            
            return correctedText
            
        } catch let decodingError as DecodingError {
            print("Decoding error: \(decodingError)")
            throw GrammarCorrectionError.apiError("Failed to parse response: \(decodingError.localizedDescription)")
        } catch {
            if error is GrammarCorrectionError {
                throw error
            } else {
                throw GrammarCorrectionError.apiError(error.localizedDescription)
            }
        }
    }
}

// MARK: - Custom Errors
enum GrammarCorrectionError: Error, LocalizedError {
    case emptyText
    case invalidURL
    case invalidResponse
    case apiError(String)
    case noCorrection
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .emptyText:
            return "Please enter some text to correct"
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .apiError(let message):
            return "API Error: \(message)"
        case .noCorrection:
            return "No grammar correction was provided"
        case .networkError:
            return "Network error. Please check your internet connection"
        }
    }
}
