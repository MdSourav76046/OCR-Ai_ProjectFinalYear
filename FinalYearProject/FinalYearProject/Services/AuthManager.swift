import Foundation
import SwiftUI
import FirebaseAuth

@MainActor
class AuthManager: ObservableObject {
    static let shared = AuthManager()
    
    @Published var email = ""
    @Published var password = ""
    @Published var isPasswordVisible = false
    
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""
    
    private let firebaseService = FirebaseService.shared
    
    private init() {
        checkAuthState()
    }
    
    // MARK: - Authentication State
    func checkAuthState() {
        if let user = Auth.auth().currentUser {
            isAuthenticated = true
        } else {
            isAuthenticated = false
        }
    }
    
    // MARK: - Form Validation
    var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty && email.isValidEmail
    }
    
    // MARK: - Sign In
    func signIn() async {
        guard isFormValid else {
            showError(message: "Please enter valid email and password")
            return
        }
        
        isLoading = true
        
        do {
            let user = try await firebaseService.signIn(email: email, password: password)
            isAuthenticated = true
        } catch {
            showError(message: error.localizedDescription)
        }
        
        isLoading = false
    }
    
    // MARK: - Sign Out
    func signOut() {
        do {
            try firebaseService.signOut()
            isAuthenticated = false
            clearForm()
        } catch {
            showError(message: error.localizedDescription)
        }
    }
    
    // MARK: - Helper Methods
    private func showError(message: String) {
        errorMessage = message
        showError = true
    }
    
    private func clearForm() {
        email = ""
        password = ""
        isPasswordVisible = false
    }
} 