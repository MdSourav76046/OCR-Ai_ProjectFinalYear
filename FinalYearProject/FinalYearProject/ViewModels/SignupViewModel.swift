import Foundation
import SwiftUI

@MainActor
class SignupViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var username = ""
    @Published var dateOfBirth = ""
    @Published var gender = ""
    @Published var isPasswordVisible = false
    @Published var showDatePicker = false
    @Published var selectedDate = Date()
    
    @Published var isLoading = false
    @Published var showError = false
    @Published var showSuccess = false
    @Published var errorMessage = ""
    
    private let firebaseService = FirebaseService.shared
    
    // MARK: - Form Validation
    var isFormValid: Bool {
        !email.isEmpty &&
        !password.isEmpty &&
        !username.isEmpty &&
        !dateOfBirth.isEmpty &&
        email.isValidEmail &&
        password.isValidPassword &&
        username.isValidUsername
    }
    
    var isFormComplete: Bool {
        !email.isEmpty && !password.isEmpty && !username.isEmpty && !dateOfBirth.isEmpty
    }
    
    // MARK: - Sign Up Methods
    func signUp() async {
        guard isFormComplete else {
            showError(message: "Please fill all required fields")
            return
        }
        
        guard isFormValid else {
            showError(message: "Please check your input format")
            return
        }
        
        isLoading = true
        
        do {
            let user = try await firebaseService.signUp(
                email: email,
                password: password,
                username: username,
                firstName: username,
                lastName: "",
                dateOfBirth: dateOfBirth.isEmpty ? nil : dateOfBirth,
                gender: gender.isEmpty ? nil : gender
            )
            
            // Clear form after successful signup
            clearForm()
            showSuccess = true
            
            AuthManager.shared.isAuthenticated = true
            
        } catch {
            showError(message: error.localizedDescription)
        }
        
        isLoading = false
    }
    
    private func clearForm() {
        email = ""
        password = ""
        username = ""
        dateOfBirth = ""
        gender = ""
        selectedDate = Date()
    }
    
    func signUpWithGoogle() {
        showError(message: "Google Sign In not implemented yet")
    }
    
    func signUpWithFacebook() {
        showError(message: "Facebook Sign In not implemented yet")
    }
    
    // MARK: - Helper Methods
    private func showError(message: String) {
        errorMessage = message
        showError = true
    }
} 