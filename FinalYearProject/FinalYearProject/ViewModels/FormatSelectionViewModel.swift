import Foundation
import SwiftUI
import UIKit

@MainActor
class FormatSelectionViewModel: ObservableObject {
    @Published var selectedFormat: OutputFormat?
    @Published var isLoading = false
    @Published var showError = false
    @Published var showSuccess = false
    @Published var errorMessage = ""
    
    private let firebaseService = FirebaseService.shared
    
    // MARK: - Document Processing
    func processDocument(image: UIImage, conversionType: ConversionType) async {
        guard let selectedFormat = selectedFormat else {
            showError(message: "Please select a format")
            return
        }
        
        isLoading = true
        
        do {
            guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                showError(message: "Failed to process image")
                return
            }
            
            let fileName = "document_\(UUID().uuidString)"
            let downloadURL = try await firebaseService.uploadDocument(imageData: imageData, fileName: fileName)
            
            // Create document record
            let document = Document(
                id: UUID().uuidString,
                fileName: fileName,
                fileType: .image,
                conversionType: conversionType,
                originalImage: downloadURL,
                outputFormat: selectedFormat
            )
            
            try await firebaseService.saveDocumentToHistory(document: document)
            
            try await simulateProcessing()
            
            showSuccess = true
            
        } catch {
            showError(message: error.localizedDescription)
        }
        
        isLoading = false
    }
    
    // MARK: - Simulate Processing
    private func simulateProcessing() async throws {
        try await Task.sleep(nanoseconds: 2_000_000_000)
    }
    
    // MARK: - Helper Methods
    private func showError(message: String) {
        errorMessage = message
        showError = true
    }
} 