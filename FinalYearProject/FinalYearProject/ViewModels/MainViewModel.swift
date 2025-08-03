import Foundation
import SwiftUI
import UIKit

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
            guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                showError(message: "Failed to process image")
                return
            }
            
            let fileName = "document_\(UUID().uuidString)"
            let downloadURL = try await firebaseService.uploadDocument(imageData: imageData, fileName: fileName)
            
            let document = Document(
                id: UUID().uuidString,
                fileName: fileName,
                fileType: .image,
                conversionType: conversionType,
                originalImage: downloadURL,
                outputFormat: .pdf
            )
            
            try await firebaseService.saveDocumentToHistory(document: document)
            
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