import Foundation
import SwiftUI

@MainActor
class MainViewModel: ObservableObject {
    @Published var selectedImage: UIImage?
    @Published var selectedConversionType: ConversionType = .cameraToPdf
    
    // Navigation Path for clean navigation
    @Published var navigationPath = NavigationPath()
    
    // Keep sheet states for image picker and camera
    @Published var showingImagePicker = false
    @Published var showingCamera = false
    
    @Published var showError = false
    @Published var errorMessage = ""
    
    private let firebaseService = FirebaseService.shared
    private let authManager = AuthManager.shared
    
    // Shared instance for reset functionality
    static let shared = MainViewModel()
    
    // MARK: - Image Selection Methods
    func imageSelected(_ image: UIImage) {
        selectedImage = image
        navigateToFormatSelection(image: image, conversionType: selectedConversionType)
    }
    
    // MARK: - Document Upload Methods
    func uploadDocument(image: UIImage, conversionType: ConversionType) async {
        // Create document record without image upload
        _ = Document(
            id: UUID().uuidString,
            fileName: "document_\(UUID().uuidString)",
            fileType: .image,
            conversionType: conversionType,
            originalImage: nil, // No image upload to avoid Storage dependency
            outputFormat: .pdf
        )
        
        // Skip Firestore save to avoid dependency issues
        // try await firebaseService.saveDocumentToHistory(document: document)
        
        navigateToFormatSelection(image: image, conversionType: conversionType)
    }
    
    // MARK: - Helper Methods
    private func showError(message: String) {
        errorMessage = message
        showError = true
    }
    
    // MARK: - Navigation Methods
    func navigateToImageEditor(image: UIImage, conversionType: ConversionType) {
        selectedImage = image
        selectedConversionType = conversionType
        navigationPath.append(NavigationDestination.imageEditor(image: image, conversionType: conversionType))
    }
    
    func navigateToFormatSelection(image: UIImage, conversionType: ConversionType) {
        navigationPath.append(NavigationDestination.formatSelection(image: image, conversionType: conversionType))
    }
    
    func navigateToTextResult(extractedText: String, originalImage: UIImage?, conversionType: String, outputFormat: String) {
        navigationPath.append(NavigationDestination.textResult(extractedText: extractedText, originalImage: originalImage, conversionType: conversionType, outputFormat: outputFormat))
    }
    
    func navigateToFileResult(fileURL: URL, fileType: String, originalImage: UIImage?) {
        navigationPath.append(NavigationDestination.fileGenerationResult(fileURL: fileURL, fileType: fileType, originalImage: originalImage))
    }
    
    func navigateToSettings() {
        navigationPath.append(NavigationDestination.settings)
    }
    
    func navigateToHistory() {
        navigationPath.append(NavigationDestination.history)
    }
    
    func navigateToSavedPDFs() {
        navigationPath.append(NavigationDestination.savedPDFs)
    }
    
    func navigateBack() {
        if !navigationPath.isEmpty {
            navigationPath.removeLast()
        }
    }
    
    func navigateToRoot() {
        navigationPath.removeLast(navigationPath.count)
    }
    
    // MARK: - Reset State
    func resetState() {
        print("🔄 MainViewModel: Resetting app state")
        selectedImage = nil
        selectedConversionType = .cameraToPdf
        showingImagePicker = false
        showingCamera = false
        showError = false
        errorMessage = ""
        
        // Clear navigation path to go back to root
        navigationPath.removeLast(navigationPath.count)
        print("✅ MainViewModel: App state reset complete")
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
