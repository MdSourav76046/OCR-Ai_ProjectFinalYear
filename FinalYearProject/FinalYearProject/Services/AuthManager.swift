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
    @Published var currentUser: User?
    
    private let firebaseService = FirebaseService.shared
    
    private init() {
        checkAuthState()
        
        // Listen for authentication state changes
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.checkAuthState()
            }
        }
    }
    
    // MARK: - Authentication State
    func checkAuthState() {
        let user = Auth.auth().currentUser
        isAuthenticated = user != nil
        
        // Clear form if user is not authenticated
        if !isAuthenticated {
            clearForm()
            currentUser = nil
        } else {
            // Load current user data if authenticated
            Task {
                await loadCurrentUser()
            }
        }
    }
    
    // MARK: - Load Current User
    private func loadCurrentUser() async {
        guard let firebaseUser = Auth.auth().currentUser else { return }
        
        do {
            let user = try await firebaseService.getUserFromFirestore(userId: firebaseUser.uid)
            currentUser = user
        } catch {
            print("Failed to load current user: \(error)")
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
            currentUser = user
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
    func showError(message: String) {
        errorMessage = message
        showError = true
    }
    
    
    private func clearForm() {
        email = ""
        password = ""
        isPasswordVisible = false
    }
} 
