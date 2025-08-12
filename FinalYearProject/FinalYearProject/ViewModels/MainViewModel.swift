import Foundation
import SwiftUI

@MainActor
class MainViewModel: ObservableObject {
    @Published var selectedImage: UIImage?
    @Published var selectedConversionType: ConversionType = .cameraToPdf
    
    @Published var showingImagePicker = false
    @Published var showingCamera = false
    @Published var showingFormatPicker = false
    
    @Published var showError = false
    @Published var errorMessage = ""
    
    private let firebaseService = FirebaseService.shared
    private let authManager = AuthManager.shared
    
    // MARK: - Image Selection Methods
    func imageSelected(_ image: UIImage) {
        selectedImage = image
        showingFormatPicker = true
    }
    
    // MARK: - Document Upload Methods
    func uploadDocument(image: UIImage, conversionType: ConversionType) async {
        do {
            // Create document record without image upload
            let document = Document(
                id: UUID().uuidString,
                fileName: "document_\(UUID().uuidString)",
                fileType: .image,
                conversionType: conversionType,
                originalImage: nil, // No image upload to avoid Storage dependency
                outputFormat: .pdf
            )
            
            // Skip Firestore save to avoid dependency issues
            // try await firebaseService.saveDocumentToHistory(document: document)
            
            showingFormatPicker = true
            
        } catch {
            showError(message: error.localizedDescription)
        }
    }
    
    // MARK: - Helper Methods
    private func showError(message: String) {
        errorMessage = message
        showError = true
    }
    
    // MARK: - Sign Out
    func signOut() {
        do {
            try firebaseService.signOut()
            authManager.signOut()
        } catch {
            showError(message: error.localizedDescription)
        }
    }
} 
