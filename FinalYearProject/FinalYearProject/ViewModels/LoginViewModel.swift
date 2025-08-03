import Foundation
import SwiftUI

@MainActor
class LoginViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var isPasswordVisible = false
    
    @Published var isLoading = false
    @Published var showError = false
    @Published var showSuccess = false
    @Published var errorMessage = ""
    
    private let firebaseService = FirebaseService.shared
    
    // MARK: - Form Validation
    var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty && email.isValidEmail
    }
    
    // MARK: - Sign In Methods
    func signIn() async {
        guard isFormValid else {
            showError(message: "Please enter valid email and password")
            return
        }
        
        isLoading = true
        
        do {
            let user = try await firebaseService.signIn(email: email, password: password)
            showSuccess = true
        } catch {
            showError(message: error.localizedDescription)
        }
        
        isLoading = false
    }
    
    func signInWithGoogle() {
        showError(message: "Google Sign In not implemented yet")
    }
    
    func signInWithFacebook() {
        showError(message: "Facebook Sign In not implemented yet")
    }
    
    func forgotPassword() {
        showError(message: "Forgot password not implemented yet")
    }
    
    // MARK: - Helper Methods
    private func showError(message: String) {
        errorMessage = message
        showError = true
    }
} 