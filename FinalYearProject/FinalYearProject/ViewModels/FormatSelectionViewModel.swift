import Foundation
import SwiftUI
import UIKit

@MainActor
class FormatSelectionViewModel: ObservableObject {
    @Published var selectedFormat: OutputFormat?
    @Published var correctGrammar = false
    @Published var isLoading = false
    @Published var showError = false
    @Published var showSuccess = false
    @Published var errorMessage = ""
    @Published var extractedText: String = ""
    @Published var showTextResult = false
    
    private let firebaseService = FirebaseService.shared
    private let mistralService = MistralAIService.shared
    private let ocrHistoryService = OCRHistoryService.shared
    private let grammarService = GrammarCorrectionService.shared
    private let applicationFormatService = ApplicationFormatService.shared
    private let wordFormatService = WordFormatService.shared
    private let pdfGenerationService = PDFGenerationService.shared
    private let docxGenerationService = DOCXGenerationService.shared
    
    // Shared instance for reset functionality
    static let shared = FormatSelectionViewModel()
    
    // MARK: - Document Processing
    func processDocument(image: UIImage, conversionType: ConversionType) async {
        guard let selectedFormat = selectedFormat else {
            showError(message: "Please select a format")
            return
        }
        
        isLoading = true
        
        do {
            // Extract text from image using Mistral AI OCR
            let rawText = try await mistralService.extractTextFromImage(image)
            extractedText = mistralService.processExtractedText(rawText)
            
            print("🔄 FormatSelectionViewModel: Processing document")
            print("📝 Extracted text: \(extractedText.prefix(50))...")
            print("🖼️ Image size: \(image.size)")
            print("🔄 Conversion type: \(conversionType.rawValue)")
            print("📄 Output format: \(selectedFormat.rawValue)")
            print("🔧 Correct grammar: \(correctGrammar)")
            
            // Apply grammar correction if enabled
            if correctGrammar && !extractedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                print("🔧 FormatSelectionViewModel: Applying grammar correction...")
                let correctedText = try await grammarService.correctGrammar(extractedText)
                extractedText = correctedText
                print("✅ FormatSelectionViewModel: Grammar correction applied")
                print("📝 Corrected text: \(extractedText.prefix(50))...")
            }
            
            // Apply format-specific processing
            var finalText = extractedText
            
            // Format as application if selected
            if selectedFormat == .application {
                print("📝 FormatSelectionViewModel: Formatting as application...")
                finalText = try await applicationFormatService.formatAsApplication(extractedText)
                print("✅ FormatSelectionViewModel: Application format applied")
                
                // Save to history
                ocrHistoryService.saveOCRResult(
                    text: finalText,
                    image: image,
                    conversionType: conversionType.rawValue,
                    outputFormat: selectedFormat.rawValue,
                    saveFullImage: false
                )
                
                // Navigate to text result
                MainViewModel.shared.navigateToTextResult(
                    extractedText: finalText,
                    originalImage: image,
                    conversionType: conversionType.rawValue,
                    outputFormat: selectedFormat.rawValue
                )
            }
            // PDF and Word formats - show editable preview first
            else if selectedFormat == .pdf || selectedFormat == .word {
                print("📝 FormatSelectionViewModel: Formatting text for \(selectedFormat.rawValue)...")
                
                // Format text for better appearance
                finalText = try await wordFormatService.formatAsWord(extractedText)
                
                // Save to history
                ocrHistoryService.saveOCRResult(
                    text: finalText,
                    image: image,
                    conversionType: conversionType.rawValue,
                    outputFormat: selectedFormat.rawValue,
                    saveFullImage: false
                )
                
                // Navigate to text result with file generation option
                MainViewModel.shared.navigateToTextResult(
                    extractedText: finalText,
                    originalImage: image,
                    conversionType: conversionType.rawValue,
                    outputFormat: selectedFormat.rawValue
                )
            }
            // Text format - just show text
            else if selectedFormat == .text {
                // Save to history
                ocrHistoryService.saveOCRResult(
                    text: extractedText,
                    image: image,
                    conversionType: conversionType.rawValue,
                    outputFormat: selectedFormat.rawValue,
                    saveFullImage: false
                )
                
                // Navigate to text result
                MainViewModel.shared.navigateToTextResult(
                    extractedText: extractedText,
                    originalImage: image,
                    conversionType: conversionType.rawValue,
                    outputFormat: selectedFormat.rawValue
                )
            }
            // Other formats - show success
            else {
                ocrHistoryService.saveOCRResult(
                    text: extractedText,
                    image: image,
                    conversionType: conversionType.rawValue,
                    outputFormat: selectedFormat.rawValue,
                    saveFullImage: false
                )
                showSuccess = true
            }
            
        } catch {
            let errorMessage: String
            if let mistralError = error as? MistralAIError {
                errorMessage = mistralError.localizedDescription
            } else if let appFormatError = error as? ApplicationFormatError {
                errorMessage = appFormatError.localizedDescription
            } else if let wordFormatError = error as? WordFormatError {
                errorMessage = wordFormatError.localizedDescription
            } else if let pdfError = error as? PDFGenerationError {
                errorMessage = pdfError.localizedDescription
            } else if let docxError = error as? DOCXGenerationError {
                errorMessage = docxError.localizedDescription
            } else {
                errorMessage = error.localizedDescription
            }
            
            showError(message: errorMessage)
            print("❌ FormatSelectionViewModel: Error occurred - \(errorMessage)")
            
            // Auto-reset state on error to ensure clean state
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.resetState()
            }
        }
        
        isLoading = false
    }
    
    // MARK: - Simulate Processing
    private func simulateProcessing() async throws {
        try await Task.sleep(nanoseconds: 2_000_000_000)
    }
    
    // MARK: - Reset State
    func resetState() {
        print("🔄 FormatSelectionViewModel: Resetting format selection state")
        selectedFormat = nil
        correctGrammar = false
        isLoading = false
        showError = false
        showSuccess = false
        errorMessage = ""
        extractedText = ""
        showTextResult = false
        print("✅ FormatSelectionViewModel: Format selection state reset complete")
    }
    
    // MARK: - Helper Methods
    private func showError(message: String) {
        errorMessage = message
        showError = true
    }
} 